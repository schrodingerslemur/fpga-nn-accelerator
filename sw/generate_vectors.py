#!/usr/bin/env python3

import argparse
import json
import random

# q1.15 fixed point helpers
SCALE = 1 << 15

def to_q15(x):
    return int(round(x * SCALE))

def from_q15(v):
    return v / SCALE

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--n', type=int, default=8, help='vector length')
    p.add_argument('--m', type=int, default=4, help='neuron count')
    p.add_argument('--seed', type=int, default=0)
    args = p.parse_args()

    random.seed(args.seed)
    in_vec = [round(random.uniform(-1,1), 4) for _ in range(args.n)]
    weights = [[round(random.uniform(-1,1),4) for _ in range(args.n)] for _ in range(args.m)]

    # convert to q15
    in_q = [to_q15(x) for x in in_vec]
    w_q = [[to_q15(x) for x in row] for row in weights]

    golden = []
    for row in w_q:
        acc = 0
        for a,b in zip(in_q, row):
            acc += a * b
        # acc is Q30 (because Q15*Q15); shift down to Q15 by >>15; keep 32-bit
        acc_shift = acc >> 15
        golden.append(acc_shift)

    with open('vectors.json','w') as f:
        json.dump({'in': in_q}, f, indent=2)
    with open('weights.json','w') as f:
        json.dump({'weights': w_q}, f, indent=2)
    with open('golden.json','w') as f:
        json.dump({'golden': golden}, f, indent=2)

    print('Wrote vectors.json, weights.json, golden.json')