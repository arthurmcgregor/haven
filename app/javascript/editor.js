// Entry point for the post editor bundle. Loaded only on post new/edit pages.
import { Editor, rootCtx, defaultValueCtx } from "@milkdown/kit/core";
import { commonmark } from "@milkdown/kit/preset/commonmark";
import { gfm } from "@milkdown/kit/preset/gfm";
import { listener, listenerCtx } from "@milkdown/kit/plugin/listener";
import { upload, uploadConfig } from "@milkdown/kit/plugin/upload";
import { replaceAll } from "@milkdown/kit/utils";
import { nord } from "@milkdown/theme-nord";

import "@milkdown/theme-nord/style.css";

function csrfToken() {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta ? meta.content : "";
}

async function uploadFile(file) {
  const formData = new FormData();
  formData.append("file", file);
  const response = await fetch("/uploads", {
    method: "POST",
    headers: { "X-CSRF-Token": csrfToken(), Accept: "application/json" },
    body: formData,
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({ error: response.statusText }));
    throw new Error(err.error || "Upload failed");
  }
  return response.json();
}

async function imageUploader(files, schema) {
  const imageNode = schema.nodes.image;
  const images = Array.from(files).filter((f) => f && f.type.startsWith("image/"));
  const results = await Promise.all(
    images.map(async (file) => ({ file, data: await uploadFile(file) })),
  );
  return results.map(({ file, data }) => imageNode.createAndFill({ src: data.url, alt: file.name }));
}

export async function initEditor(container, textarea) {
  const initialContent = textarea.value || "";

  const editor = await Editor.make()
    .config(nord)
    .config((ctx) => {
      ctx.set(rootCtx, container);
      ctx.set(defaultValueCtx, initialContent);

      ctx.get(listenerCtx).markdownUpdated((_ctx, markdown, prevMarkdown) => {
        if (markdown !== prevMarkdown) {
          textarea.value = markdown;
        }
      });

      ctx.update(uploadConfig.key, (prev) => ({
        ...prev,
        uploader: imageUploader,
      }));
    })
    .use(commonmark)
    .use(gfm)
    .use(listener)
    .use(upload)
    .create();

  // Stash on the container so the media-attach button (wired after init) can
  // replay new markdown through the editor.
  container._milkdownAppend = (htmlSnippet) => {
    const next = `${textarea.value}${htmlSnippet}`;
    textarea.value = next;
    editor.action(replaceAll(next));
  };

  return editor;
}

export async function attachMediaFile(container, file) {
  const data = await uploadFile(file);
  container._milkdownAppend(data.html);
}

function wireMediaAttach(container) {
  const fileInput = document.getElementById("media-attach");
  const button = document.getElementById("media-upload-btn");
  if (!fileInput || !button) return;

  button.addEventListener("click", async () => {
    const file = fileInput.files[0];
    if (!file) return;
    button.disabled = true;
    try {
      await attachMediaFile(container, file);
      fileInput.value = "";
    } catch (e) {
      console.error(e);
      alert(`Upload failed: ${e.message}`);
    } finally {
      button.disabled = false;
    }
  });
}

function autoFillDateTime() {
  const contentField = document.getElementById("post_content");
  if (!contentField || contentField.value.trim() !== "") return;
  const now = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  const dateField = document.getElementById("post_date");
  const timeField = document.getElementById("post_time");
  if (dateField) dateField.value = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
  if (timeField) timeField.value = `${pad(now.getHours())}:${pad(now.getMinutes())}`;
}

document.addEventListener("DOMContentLoaded", () => {
  const container = document.querySelector("[data-milkdown]");
  const textarea = document.getElementById("post_content");
  if (!container || !textarea) return;
  autoFillDateTime();
  initEditor(container, textarea)
    .then(() => wireMediaAttach(container))
    .catch((e) => console.error("Milkdown init failed:", e));
});
