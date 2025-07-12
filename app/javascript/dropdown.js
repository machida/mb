// ドロップダウンメニューの制御
function initializeDropdown() {
  const dropdownButton = document.querySelector('.js-dropdown-button');
  const dropdownMenu = document.querySelector('.js-dropdown-menu');
  
  if (dropdownButton && dropdownMenu) {
    // 既にイベントリスナーが設定されているかチェック
    if (dropdownButton.hasAttribute('data-dropdown-initialized')) {
      return;
    }
    
    function openDropdown() {
      dropdownMenu.classList.add('is-open');
      dropdownButton.setAttribute('aria-expanded', 'true');
    }
    
    function closeDropdown() {
      dropdownMenu.classList.remove('is-open');
      dropdownButton.setAttribute('aria-expanded', 'false');
    }
    
    // ドロップダウンボタンのクリックイベント処理関数
    function handleDropdownClick(e) {
      e.preventDefault();
      e.stopPropagation();
      
      const isOpen = dropdownMenu.classList.contains('is-open');
      
      if (isOpen) {
        closeDropdown();
      } else {
        openDropdown();
      }
    }
    
    // ドロップダウンボタンのクリックイベント
    dropdownButton.addEventListener('click', handleDropdownClick);
    
    // ドキュメント全体のクリックでドロップダウンを閉じる
    document.addEventListener('click', function(e) {
      if (dropdownButton && dropdownMenu && 
          !dropdownButton.contains(e.target) && !dropdownMenu.contains(e.target)) {
        closeDropdown();
      }
    });
    
    // ESCキーでドロップダウンを閉じる
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && dropdownMenu) {
        closeDropdown();
      }
    });
    
    // 初期化済みマークを設定
    dropdownButton.setAttribute('data-dropdown-initialized', 'true');
  }
}

// Turbo対応: 初期ロードとTurbo navigaionの両方で実行
document.addEventListener('DOMContentLoaded', initializeDropdown);
document.addEventListener('turbo:load', initializeDropdown);
document.addEventListener('turbo:render', initializeDropdown);