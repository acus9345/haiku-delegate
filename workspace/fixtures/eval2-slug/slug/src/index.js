'use strict';

/**
 * Turn a string into a lowercase, dash-separated URL slug.
 * @param {string} input
 * @returns {string}
 */
function slugify(input) {
  return String(input)
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s/g, '-');
}

module.exports = { slugify };
