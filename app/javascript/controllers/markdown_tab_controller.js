import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editTab", "previewTab", "editPanel", "previewPanel"]

  connect() {
    this.showEdit()
  }

  showEdit() {
    // タブの状態を更新
    this.editTabTarget.classList.add("is--active")
    this.editTabTarget.classList.remove("is--inactive")
    this.editTabTarget.setAttribute("aria-selected", "true")

    this.previewTabTarget.classList.remove("is--active")
    this.previewTabTarget.classList.add("is--inactive")
    this.previewTabTarget.setAttribute("aria-selected", "false")

    // パネルの表示/非表示を切り替え
    this.editPanelTarget.classList.remove("hidden")
    this.previewPanelTarget.classList.add("hidden")
  }

  showPreview() {
    // タブの状態を更新
    this.previewTabTarget.classList.add("is--active")
    this.previewTabTarget.classList.remove("is--inactive")
    this.previewTabTarget.setAttribute("aria-selected", "true")

    this.editTabTarget.classList.remove("is--active")
    this.editTabTarget.classList.add("is--inactive")
    this.editTabTarget.setAttribute("aria-selected", "false")

    // パネルの表示/非表示を切り替え
    this.editPanelTarget.classList.add("hidden")
    this.previewPanelTarget.classList.remove("hidden")
  }
}
