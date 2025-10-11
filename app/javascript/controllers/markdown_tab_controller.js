import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editTab", "previewTab", "editPanel", "previewPanel"]

  connect() {
    this.showEdit()
  }

  showEdit() {
    // タブの状態を更新
    this.editTabTarget.classList.add("border-indigo-600", "text-indigo-600")
    this.editTabTarget.classList.remove("border-transparent", "text-gray-500")
    this.editTabTarget.setAttribute("aria-selected", "true")

    this.previewTabTarget.classList.remove("border-indigo-600", "text-indigo-600")
    this.previewTabTarget.classList.add("border-transparent", "text-gray-500")
    this.previewTabTarget.setAttribute("aria-selected", "false")

    // パネルの表示/非表示を切り替え
    this.editPanelTarget.classList.remove("hidden")
    this.previewPanelTarget.classList.add("hidden")
  }

  showPreview() {
    // タブの状態を更新
    this.previewTabTarget.classList.add("border-indigo-600", "text-indigo-600")
    this.previewTabTarget.classList.remove("border-transparent", "text-gray-500")
    this.previewTabTarget.setAttribute("aria-selected", "true")

    this.editTabTarget.classList.remove("border-indigo-600", "text-indigo-600")
    this.editTabTarget.classList.add("border-transparent", "text-gray-500")
    this.editTabTarget.setAttribute("aria-selected", "false")

    // パネルの表示/非表示を切り替え
    this.editPanelTarget.classList.add("hidden")
    this.previewPanelTarget.classList.remove("hidden")
  }
}
