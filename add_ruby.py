import tkinter as tk

# ウィンドウの作成
root = tk.Tk()
root.title('二つのテキスト入力フィールド')

# ラベルとエントリー1
label1 = tk.Label(root, text='入力1:')
label1.pack()
entry1 = tk.Entry(root)
entry1.pack()

# ラベルとエントリー2
label2 = tk.Label(root, text='入力2:')
label2.pack()
entry2 = tk.Entry(root)
entry2.pack()

# 入力値を格納する変数
input1 = ''
input2 = ''

def save_inputs():
    global input1, input2
    input1 = entry1.get()
    input2 = entry2.get()
    print(f'入力1: {input1}')
    print(f'入力2: {input2}')

# ボタン
save_button = tk.Button(root, text='保存', command=save_inputs)
save_button.pack()

root.mainloop()