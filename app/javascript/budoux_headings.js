import { loadDefaultJapaneseParser } from "budoux"

const parser = loadDefaultJapaneseParser()
const SELECTOR = [
  ".a--heading",
  ".a--prose h1",
  ".a--prose h2",
  ".a--prose h3",
  ".a--prose h4",
  ".a--prose h5",
  ".a--prose h6",
].join(", ")

const apply = () => {
  document.querySelectorAll(SELECTOR).forEach((el) => {
    if (el.classList.contains("budoux-applied")) return
    parser.applyToElement(el)
    el.classList.add("budoux-applied")
  })
}

document.addEventListener("turbo:load", apply)
document.addEventListener("turbo:frame-load", apply)
