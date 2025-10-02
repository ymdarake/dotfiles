#!/bin/bash
#
# VSCodeから呼び出すためのTmux起動スクリプト
#
# -A: 存在するセッションにアタッチし、なければ作成する
# -s vscode: セッション名を "vscode" に固定する

tmux new-session -A -s vscode

