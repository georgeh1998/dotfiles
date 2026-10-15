#!/usr/bin/env python3
# PreToolUse(Bash) hook: 危険なbashコマンドをブロックする
#   - プロジェクト外のファイルに対する rm
#   - git push の強制push (-f / --force / --force-with-lease / +refspec)
# exit 2 で終了するとツール実行がブロックされ、stderr の内容が Claude に返される

import json
import os
import re
import shlex
import sys

SEPARATORS = {";", "&&", "||", "|", "&", "\n"}
PREFIX_COMMANDS = {"sudo", "command", "builtin", "exec", "nohup", "time", "env", "xargs"}


def block(reason):
    print(f"Blocked by bash-guard hook: {reason}", file=sys.stderr)
    sys.exit(2)


def split_segments(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|")
    lexer.whitespace_split = True
    segments, current = [], []
    for token in lexer:
        if token in SEPARATORS or set(token) <= set(";&|"):
            if current:
                segments.append(current)
            current = []
        else:
            current.append(token)
    if current:
        segments.append(current)
    return segments


def strip_prefix(tokens):
    # sudo / env VAR=x などの前置きを取り除いて実コマンドを先頭にする
    while tokens:
        head = tokens[0]
        if head in PREFIX_COMMANDS or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", head):
            tokens = tokens[1:]
        elif head.startswith("-") and len(tokens) > 1:
            tokens = tokens[1:]
        else:
            break
    return tokens


def is_inside(path, project_dir):
    real = os.path.realpath(path)
    return real == project_dir or real.startswith(project_dir + os.sep)


def check_rm(args, cwd, project_dir):
    for arg in args:
        if arg.startswith("-"):
            continue
        if "$" in arg or "`" in arg:
            block(f"rm の対象に変数展開が含まれており安全か判定できません: {arg}")
        target = os.path.expanduser(arg)
        if not os.path.isabs(target):
            target = os.path.join(cwd, target)
        if not is_inside(target, project_dir):
            block(f"プロジェクト外のファイルの rm は禁止されています: {arg} (project: {project_dir})")


def check_git_push(args):
    # git -C dir push ... のようなグローバルオプションを飛ばして push を探す
    if "push" not in args:
        return
    push_args = args[args.index("push") + 1:]
    for arg in push_args:
        if arg in ("-f", "--force") or arg.startswith("--force"):
            block(f"git push の強制push は禁止されています: {arg}")
        if re.match(r"^-[A-Za-z]*f[A-Za-z]*$", arg):
            block(f"git push の強制push は禁止されています: {arg}")
        if arg.startswith("+"):
            block(f"git push の強制push (+refspec) は禁止されています: {arg}")


def main():
    data = json.load(sys.stdin)
    command = data.get("tool_input", {}).get("command", "")
    if not command:
        return
    cwd = data.get("cwd") or os.getcwd()
    project_dir = os.path.realpath(os.environ.get("CLAUDE_PROJECT_DIR") or cwd)

    try:
        segments = split_segments(command)
    except ValueError:
        # クォート不整合などでパースできない場合、危険ワードを含むなら安全側に倒す
        if re.search(r"\brm\b", command) or re.search(r"\bgit\b.*\bpush\b", command):
            block("コマンドを解析できなかったため rm / git push を含むコマンドをブロックしました")
        return

    for tokens in segments:
        tokens = strip_prefix(tokens)
        if not tokens:
            continue
        name = os.path.basename(tokens[0])
        args = tokens[1:]
        if name == "cd":
            # 同一コマンド内の cd を追跡して rm の相対パスを正しく解決する
            dest = os.path.expanduser(args[0]) if args else os.path.expanduser("~")
            cwd = os.path.normpath(os.path.join(cwd, dest))
        elif name in ("rm", "rmdir", "unlink"):
            check_rm(args, cwd, project_dir)
        elif name == "git":
            check_git_push(args)


if __name__ == "__main__":
    main()
