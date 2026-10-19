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

test('collapses spaces around a dash into one dash (#41)', () => {
  assert.strictEqual(slugify('Rock - Paper'), 'rock-paper');
});

test('collapses separators left behind by removed punctuation (#41)', () => {
  assert.strictEqual(slugify('Salt , Pepper -- Oil'), 'salt-pepper-oil');
});

test('collapses mixed whitespace into one dash (#41)', () => {
  assert.strictEqual(slugify('tab\there\n\nnewline'), 'tab-here-newline');
});
