'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { slugify } = require('../src/index.js');

test('lowercases and dashes words', () => {
  assert.strictEqual(slugify('Hello World'), 'hello-world');
});

test('strips punctuation', () => {
  assert.strictEqual(slugify('Hello, World!'), 'hello-world');
});

test('removes accents', () => {
  assert.strictEqual(slugify('Crème Brûlée'), 'creme-brulee');
});

test('collapses repeated spaces into one dash (#41)', () => {
  assert.strictEqual(slugify('Hello   World'), 'hello-world');
});

test('collapses runs of spaces and dashes into one dash (#41)', () => {
  assert.strictEqual(slugify('Rock - Paper'), 'rock-paper');
  assert.strictEqual(slugify('a--b'), 'a-b');
});
