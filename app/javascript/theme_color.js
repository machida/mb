// Theme Color Selection
document.addEventListener("turbo:load", () => {
  const themeColorOptions = document.querySelectorAll(".js--theme-color-option");

  if (themeColorOptions.length === 0) return;

  // 選択状態を更新する関数
  function updateSelection() {
    themeColorOptions.forEach((option) => {
      const radio = option.querySelector(".js--theme-color-input");

      if (radio.checked) {
        option.classList.add("is--selected");
      } else {
        option.classList.remove("is--selected");
      }
    });
  }

  // 初期状態を設定
  updateSelection();

  // クリック時に選択状態を更新
  themeColorOptions.forEach((option) => {
    option.addEventListener("click", () => {
      updateSelection();
    });
  });
});
