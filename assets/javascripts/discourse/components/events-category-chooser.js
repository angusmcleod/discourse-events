import CategoryChooser from "select-kit/components/category-chooser";

export default CategoryChooser.extend({
  classNames: ["events-category-chooser"],

  selectKitOptions: {
    allowUncategorized: false,
  },

  categoriesByScope() {
    return this._super().filter((category) => category.events_enabled);
  },
});
