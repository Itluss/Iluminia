import type { Tier } from './progress';

export interface Order {
  num: number;
  den: number;
}

const NUM_WORDS = ['', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept'];
const DEN_WORDS: Record<number, string> = { 3: 'tiers', 4: 'quart', 6: 'sixième', 8: 'huitième' };

// « trois quarts », « une moitié », « cinq sixièmes »…
export function orderInWords({ num, den }: Order): string {
  if (den === 2) return num === 1 ? 'une moitié' : `${NUM_WORDS[num]} moitiés`;
  const base = DEN_WORDS[den];
  const word = num === 1 ? base : den === 3 ? base : `${base}s`;
  return `${num === 1 ? 'un' : NUM_WORDS[num]} ${word}`;
}

const DENS_BY_TIER: Record<Tier, number[]> = {
  0: [2, 4],
  1: [2, 3, 4],
  2: [3, 4, 6, 8],
};

// Commandes toujours < 1 tarte (fractions propres) ; palier 0 : numérateur 1 uniquement.
export function generateOrders(t: Tier, count: number): Order[] {
  const dens = DENS_BY_TIER[t];
  const orders: Order[] = [];
  while (orders.length < count) {
    const den = dens[Math.floor(Math.random() * dens.length)];
    const num = t === 0 ? 1 : 1 + Math.floor(Math.random() * (den - 1));
    const prev = orders[orders.length - 1];
    if (prev && prev.num === num && prev.den === den) continue; // pas deux fois la même d'affilée
    orders.push({ num, den });
  }
  return orders;
}
