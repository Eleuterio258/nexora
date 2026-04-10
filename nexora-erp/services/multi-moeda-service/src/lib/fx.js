'use strict';

function roundAmount(value, decimals = 2) {
  const factor = 10 ** decimals;
  return Math.round((Number(value) + Number.EPSILON) * factor) / factor;
}

module.exports = { roundAmount };
