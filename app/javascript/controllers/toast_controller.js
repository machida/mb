import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['toast'];

  connect() {
    // トーストを表示
    this.show();
    
    // 4秒後に自動で消す
    setTimeout(() => {
      this.hide();
    }, 4000);
  }

  show() {
    this.toastTarget.classList.add('translate-x-0');
    this.toastTarget.classList.remove('translate-x-full');
  }

  hide() {
    this.toastTarget.classList.add('translate-x-full');
    this.toastTarget.classList.remove('translate-x-0');
    
    // アニメーション完了後に要素を削除
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }

  close() {
    this.hide();
  }
}