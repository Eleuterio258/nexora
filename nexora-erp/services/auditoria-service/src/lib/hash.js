'use strict';

const crypto = require('crypto');

function makeHash(payload) {
  return crypto.createHash('sha256').update(payload).digest('hex');
}

module.exports = { makeHash };
