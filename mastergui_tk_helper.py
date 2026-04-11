#!/usr/bin/env python3
import sys
import os
import tkinter as tk
from tkinter import ttk, messagebox

def read_text(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()
    except Exception as e:
        return f"Could not read file: {path}\nError: {e}"

def copy_to_clipboard(root: tk.Tk, text: str) -> None:
    root.clipboard_clear()
    root.clipboard_append(text)
    root.update()

def popup_mode(title: str, body_file: str) -> None:
    text = read_text(body_file)

    root = tk.Tk()
    root.title(title)
    root.geometry("900x650")

    frame = ttk.Frame(root, padding=10)
    frame.pack(fill="both", expand=True)

    label = ttk.Label(frame, text=title)
    label.pack(anchor="w", pady=(0, 8))

    txt = tk.Text(frame, wrap="word")
    txt.pack(fill="both", expand=True)
    txt.insert("1.0", text)
    txt.configure(state="normal")

    copy_to_clipboard(root, text)

    btn_frame = ttk.Frame(frame)
    btn_frame.pack(fill="x", pady=(8, 0))

    def copy_again() -> None:
        copy_to_clipboard(root, txt.get("1.0", "end-1c"))
        messagebox.showinfo("Copied", "Text copied to clipboard again.")

    ttk.Button(btn_frame, text="Copy Again", command=copy_again).pack(side="left", padx=4)
    ttk.Button(btn_frame, text="Close", command=root.destroy).pack(side="left", padx=4)

    root.mainloop()

def threshold_mode(body_file: str, threshold_file: str) -> None:
    intro_text = read_text(body_file)

    root = tk.Tk()
    root.title("MasterGUI Threshold Help")
    root.geometry("950x760")

    outer = ttk.Frame(root, padding=10)
    outer.pack(fill="both", expand=True)

    ttk.Label(outer, text="Copy this text to ChatGPT, then paste improved threshold values below.").pack(anchor="w")

    intro = tk.Text(outer, height=18, wrap="word")
    intro.pack(fill="x", expand=False, pady=(6, 10))
    intro.insert("1.0", intro_text)
    copy_to_clipboard(root, intro_text)

    btns_top = ttk.Frame(outer)
    btns_top.pack(fill="x", pady=(0, 10))

    def copy_intro() -> None:
        copy_to_clipboard(root, intro.get("1.0", "end-1c"))
        messagebox.showinfo("Copied", "Threshold help text copied again.")

    ttk.Button(btns_top, text="Copy Again", command=copy_intro).pack(side="left", padx=4)

    ttk.Label(outer, text="Paste new threshold values here:").pack(anchor="w")

    editor = tk.Text(outer, wrap="word")
    editor.pack(fill="both", expand=True)

    if os.path.exists(threshold_file):
        try:
            with open(threshold_file, "r", encoding="utf-8", errors="replace") as f:
                editor.insert("1.0", f.read())
        except Exception:
            pass

    def save_threshold() -> None:
        content = editor.get("1.0", "end-1c").strip()
        if not content:
            messagebox.showerror("Error", "Threshold content is empty.")
            return
        try:
            with open(threshold_file, "w", encoding="utf-8") as f:
                f.write(content + "\n")
            messagebox.showinfo("Saved", f"Updated:\n{threshold_file}")
        except Exception as e:
            messagebox.showerror("Error", str(e))

    btns_bottom = ttk.Frame(outer)
    btns_bottom.pack(fill="x", pady=(10, 0))

    ttk.Button(btns_bottom, text="Update Threshold", command=save_threshold).pack(side="left", padx=4)
    ttk.Button(btns_bottom, text="Close", command=root.destroy).pack(side="left", padx=4)

    root.mainloop()

def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: mastergui_tk_helper.py popup <title> <body_file> | threshold <body_file> <threshold_file>")
        sys.exit(1)

    mode = sys.argv[1]

    if mode == "popup":
        if len(sys.argv) != 4:
            sys.exit(1)
        popup_mode(sys.argv[2], sys.argv[3])
    elif mode == "threshold":
        if len(sys.argv) != 4:
            sys.exit(1)
        threshold_mode(sys.argv[2], sys.argv[3])
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
