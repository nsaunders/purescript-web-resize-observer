"use strict";

exports._resizeObserver = function (callback) {
  return new ResizeObserver(callback);
};

exports._observe = function (element, options, observer) {
  observer.observe(element, options);
};

exports._unobserve = function (element, observer) {
  observer.unobserve(element);
};

exports._disconnect = function (observer) {
  return observer.disconnect();
};

