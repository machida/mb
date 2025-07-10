// ドロップダウンメニューの制御
document.addEventListener('DOMContentLoaded', function() {
  const dropdownButton = document.querySelector('.js-dropdown-button');
  const dropdownMenu = document.querySelector('.js-dropdown-menu');
  
  if (dropdownButton && dropdownMenu) {
    // ドロップダウンボタンのクリックイベント
    dropdownButton.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      
      const isOpen = dropdownMenu.classList.contains('is-open');
      
      if (isOpen) {
        closeDropdown();
      } else {
        openDropdown();
      }
    });
    
    // ドキュメント全体のクリックでドロップダウンを閉じる
    document.addEventListener('click', function(e) {
      if (!dropdownButton.contains(e.target) && !dropdownMenu.contains(e.target)) {
        closeDropdown();
      }
    });
    
    // ESCキーでドロップダウンを閉じる
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        closeDropdown();
      }
    });
  }
  
  function openDropdown() {
    dropdownMenu.classList.add('is-open');
    dropdownButton.setAttribute('aria-expanded', 'true');
  }
  
  function closeDropdown() {
    dropdownMenu.classList.remove('is-open');
    dropdownButton.setAttribute('aria-expanded', 'false');
  }
});