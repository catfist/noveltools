#!/bin/bash

# [メモ]
# タイトルは文中に含めるが、サブタイトルは含めない。理由は以下の通り
# 1. ファイルの切れ目＝ページの切れ目であり、サブタイトルは必ずページの切れ目に位置すること
# 2. 執筆中にサブタイトルが見えていた方がよいこと

# 引数を受け取る
for f in "$@"
do
	export LANG="ja_JP.UTF-8"
	cd "$f"

	# 文字数カウント
	find . -type f -name "*.md" -exec cat {} \; | tr -d '\n' | tr -d '\r' | wc -m | pbcopy # Ulyssesのカウントに合わせるため改行を除く
	osascript -e "display notification \"$(pbpaste) chacters\" with title \"Count characters of files in folder(multibyte)\""

	# パラメータのチェック
	if [ -z "$1" ]; then
		echo "ディレクトリパスを指定してください。"
		exit 1
	fi

	# ディレクトリの存在確認
	if [ ! -d "$1" ]; then
		echo "指定されたディレクトリが存在しません。"
		exit 1
	fi

	# 親ディレクトリの特定
	parent_dir=$(dirname "$1")

	# プロダクトディレクトリの作成
	product_dir="$parent_dir/product"
	mkdir -p "$product_dir"

	# タイトルの抽出とプロダクトファイルの初期化
	title=$(grep -h "^# " ./*.md | sed -n 's/^# *\(.*\)/\1/p')
	tmp_file_ao="$product_dir"/tmp_ao.txt
	echo "${title}［＃「${title}」は大見出し］" >> "$tmp_file_ao"
	tmp_file_px="$product_dir"/tmp_px.txt
	product_file_ao="$product_dir/$title".txt
	product_file_aop="$product_dir/$title".pdf
	product_file_px="$product_dir/$title"_pixiv.txt
	# echo "" > "$product_file"

	# ソースファイルの結合
	for file in "$1"/*.md; do
		filename=$(basename "$file")
		numbering=$(echo "$filename" | sed 's/\([0-9_-]*\).*\.md/\1/')

		# 青空文庫
		header_ao=$(echo "$filename" | sed -n 's/^[0-9_-]*\(.*\).md/\1/p' | sed 's/＊//' | sed -n 's/\(..*\)/\1［＃「\1」は中見出し］/p') # ヘッダを抽出し、文字列があれば中見出しに変換

		if [ -n "$numbering" ]; then # ナンバリングのあるファイルの場合
			if echo "$filename" | grep -q "＊.md$"; then # ファイル名の末尾が "＊" の場合
				echo "［＃改丁］" >> "$tmp_file_ao"
			else
				echo "［＃改ページ］" >> "$tmp_file_ao"
			fi
		fi

		# Pixiv
		if [ "${#header_ao}" != 0 ]; then # 見出しのあるファイルの場合：空文字列判定がうまく動作しなかったため文字数判定
			echo "$header_ao" >> "$tmp_file_ao"
		fi

		cat "$file" | sed '/^#/d' >> "$tmp_file_ao" # タイトルを除いて追記

		header_px=$(echo "$filename" | sed -n 's/^[0-9_-]*\(.*\).md/\1/p' | sed 's/＊//' | sed -n 's/\(..*\)/[chapter:\1]/p') # ヘッダを抽出し、文字列があれば中見出しに変換

		if [ -n "$numbering" ]; then # ナンバリングのあるファイルの場合
			echo "[newpage]" >> "$tmp_file_px"
		fi

		if [ "${#header_px}" != 0 ]; then # 見出しのあるファイルの場合：空文字列判定がうまく動作しなかったため文字数判定
			echo "$header_px" >> "$tmp_file_px"
		fi

		cat "$file" | sed '/^#/d' >> "$tmp_file_px" # タイトルを除いて追記
	done

	# Mac濁点・半濁点対策
	iconv -f utf-8-mac -t utf-8 "$tmp_file_ao" > "$product_file_ao"
	iconv -f utf-8-mac -t utf-8 "$tmp_file_px" > "$product_file_px"
	rm "$product_dir"/tmp_*.txt
	# 最初の改ページまたは改丁を削除/Pixiv用ルビに変換
	sed -i '' -E -e 2d "$product_file_ao" # [#todo] 大見出し有無判定
	sed -i '' -E -e 's/｜([^《]+)《([^》]+)》/[[rb:\1>\2]]/g' -e 1d "$product_file_px"

	# 青空文庫ファイルpdf変換
	# [#note] Dropbox内のファイルを直接ソース/アウトプットに指定するとエラーになるためcpコマンドで変換前後にコピー
	cd ~/Documents/aop310/
	cp -f "$product_file_ao" source.txt
	java -jar AOP3.jar -encoding UTF-8 source.txt product_ao.pdf aop.xml
	cp -f product_ao.pdf "$product_file_aop"
	rm source.txt
	# java -jar AOP3.jar -encoding UTF-8 "$product_file_ao" "product_file_aop" aop.xml

	# iCloud Driveへコピー
	cp -f "$product_file_ao" "$HOME/Library/Mobile Documents/com~apple~CloudDocs/books"

	echo "プロダクトファイルが作成されました"

	# プロダクトディレクトリを開く
	open "$product_dir"
done
