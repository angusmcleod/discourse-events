import EmberObject from "@ember/object";

export function filtersMatch(filters1, filters2) {
  if ((filters1 && !filters2) || (!filters1 && filters2)) {
    return false;
  }

  if (!filters1 && !filters2) {
    return true;
  }

  if (filters1.length !== filters2.length) {
    return false;
  }

  return filters1.every((f1) =>
    filters2.some((f2) => {
      return (
        f2.query_column === f1.query_column &&
        f2.query_operator === f2.query_operator &&
        f2.query_value === f1.query_value
      );
    })
  );
}

const Filter = EmberObject.extend();

export default Filter;
