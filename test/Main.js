import impl from "file-url";

export function fileURL(s) {
  return function() {
    return impl(s);
  };
};
