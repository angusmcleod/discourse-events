function convertName(string) {
  return string.replace(/[_\-]+/g, " ").toLowerCase();
}

function contentsMap(items) {
  return items.map((item) => {
    return {
      id: item,
      name: convertName(item),
    };
  });
}

export { convertName, contentsMap };
