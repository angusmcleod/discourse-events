import { computed } from "@ember/object";
import CategoryChooser from "select-kit/components/category-chooser";

export default class EventsCategoryChooser extends CategoryChooser {
  @computed(
    "selectKit.filter",
    "selectKit.options.scopedCategoryId",
    "selectKit.options.prioritizedCategoryId",
    "client"
  )
  get content() {
    return super(...arguments);
  }

  categoriesByScope() {
    const categories = super.categoriesByScope();

    if (this.client === "discourse_events") {
      return categories.filter((category) => category.events_enabled);
    } else {
      return categories;
    }
  }
}
