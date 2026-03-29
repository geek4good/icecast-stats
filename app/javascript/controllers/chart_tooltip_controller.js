import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "tooltip", "title", "avg", "max", "median"]

  connect() {
    this.hideTooltip = this.hideTooltip.bind(this)
    this.element.addEventListener("mouseleave", this.hideTooltip)
  }

  disconnect() {
    this.element.removeEventListener("mouseleave", this.hideTooltip)
  }

  barTargetConnected(bar) {
    bar.addEventListener("mouseenter", () => this.showTooltip(bar))
    bar.addEventListener("mouseleave", this.hideTooltip)
  }

  showTooltip(bar) {
    this.titleTarget.textContent = bar.dataset.label
    this.avgTarget.textContent = bar.dataset.avg
    this.maxTarget.textContent = bar.dataset.max
    this.medianTarget.textContent = bar.dataset.median

    this.tooltipTarget.hidden = false

    const barRect = bar.getBoundingClientRect()
    const chartRect = this.element.getBoundingClientRect()
    const tipRect = this.tooltipTarget.getBoundingClientRect()

    let left = barRect.left - chartRect.left + barRect.width / 2 - tipRect.width / 2
    left = Math.max(0, Math.min(left, chartRect.width - tipRect.width))

    const top = barRect.top - chartRect.top - tipRect.height - 8

    this.tooltipTarget.style.left = `${left}px`
    this.tooltipTarget.style.top = `${top}px`
  }

  hideTooltip() {
    this.tooltipTarget.hidden = true
  }
}
