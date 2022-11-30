"use strict";

export function _resizeObserver(callback) {
  return new ResizeObserver(callback);
};

export function _observe(element, options, observer) {
  observer.observe(element, options);
};

export function _unobserve(element, observer) {
  observer.unobserve(element);
};

export function _disconnect(observer) {
  return observer.disconnect();
};
