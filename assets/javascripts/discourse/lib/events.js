import I18n from "I18n";

function convertName(string) {
  return string.replace(/[_\-]+/g, " ").toLowerCase();
}

function contentsMap(items, key = null) {
  return items.map((item) => {
    return {
      id: item,
      name: key ? I18n.t(`${key}.${item}`) : convertName(item),
    };
  });
}

export { convertName, contentsMap };
