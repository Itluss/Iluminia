// Modèle de maîtrise v1 : un simple historique de réussites par compétence,
// persisté en localStorage. À raffiner quand on aura des données réelles.

export type CompetenceId = 'FRA-01' | 'FRA-02' | 'FRA-03' | 'FRA-04' | 'FRA-05';

export type Tier = 0 | 1 | 2;

interface SaveData {
  missions: { bakery: number }; // nombre de fois terminée
  competences: Partial<Record<CompetenceId, boolean[]>>; // historique des réussites (les 20 dernières)
}

const KEY = 'eluminia-save-v1';

function load(): SaveData {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) {
      const data = JSON.parse(raw) as SaveData;
      if (data.missions && data.competences) return data;
    }
  } catch {
    // sauvegarde corrompue : on repart de zéro
  }
  return { missions: { bakery: 0 }, competences: {} };
}

export const save: SaveData = load();

export function persist(): void {
  localStorage.setItem(KEY, JSON.stringify(save));
}

export function record(id: CompetenceId, success: boolean): void {
  const hist = (save.competences[id] ??= []);
  hist.push(success);
  if (hist.length > 20) hist.shift();
  persist();
}

// La difficulté monte avec les réussites cumulées : 3 réussites → palier 1, 6 → palier 2.
export function tier(id: CompetenceId): Tier {
  const successes = (save.competences[id] ?? []).filter(Boolean).length;
  return successes >= 6 ? 2 : successes >= 3 ? 1 : 0;
}
