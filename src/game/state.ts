// État de jeu centralisé. Pas de persistance pour ce POC,
// mais tout passe par ici pour brancher un localStorage plus tard.

export interface GameState {
  xp: number;
  xpNextLevel: number;
  level: number;
  coins: number;
  crystals: number;
  stars: number;
  planches: number;
  questionDone: boolean;
  dialogueOpen: boolean;
  inventoryOpen: boolean;
}

export const gameState: GameState = {
  xp: 0,
  xpNextLevel: 50,
  level: 1,
  coins: 0,
  crystals: 0,
  stars: 0,
  planches: 0,
  questionDone: false,
  dialogueOpen: false,
  inventoryOpen: false,
};

export function uiOpen(): boolean {
  return gameState.dialogueOpen || gameState.inventoryOpen;
}
