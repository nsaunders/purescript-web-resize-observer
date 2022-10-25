export const _resizeObserver = function (callback) {
  return new ResizeObserver(callback);
};

export const _observe = function (element, options, observer) {
  observer.observe(element, options);
};

export const _unobserve = function (element, observer) {
  observer.unobserve(element);
};

export const _disconnect = function (observer) {
  return observer.disconnect();
};

