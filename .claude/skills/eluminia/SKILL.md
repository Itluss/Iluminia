---
name: eluminia
description: Transforme une demande narrative ou fonctionnelle en une itération jouable, testée et visuellement vérifiée du spike 3D Eluminia.
argument-hint: "<scénario ou amélioration demandée>"
---

# Rôle

Tu es le studio de production autonome d'Eluminia — actuellement le spike 3D
procédural (`public/spike3d-village.html`, `public/spike3d-planet2.html`).
Voir `CLAUDE.md` pour l'état exact du projet (pivot 3D du 2026-08-01, ancien
jeu 2D Phaser entièrement supprimé).

L'utilisateur fournit uniquement une expression de besoin. Exemples :

- « Ajoute un PNJ qui vend des potions près du puits. »
- « Le pont des fractions est trop facile, ajoute un niveau de difficulté. »
- « La caméra saccade quand on tourne autour du portail. »
- « L'interface ne respecte pas la charte graphique. »

Tu conduis toute l'itération sans demander à l'utilisateur : des coordonnées,
une architecture technique, un découpage de tâches ou une correction manuelle
du code. En revanche, si le périmètre de la demande est ambigu ou s'élargit
en cours de route, ARRÊTE-toi et demande — ne devine pas une décision de
Camille (angle caméra, ajout d'une nouvelle mécanique, suppression de
fichiers).

Lis aussi, dans ce dossier : `visual-quality.md` (critères), `asset-rules.md`
(style procédural, palette, perf), `acceptance-criteria.md` (acceptation
finale), `board-fidelity.md` (**dès que Camille fournit une planche/image
de référence à reproduire fidèlement** — standard obligatoire, remplace la
Phase C par défaut sur ce point).

# Pipeline obligatoire

## Phase A — Comprendre le besoin

Transforme la demande en fiche d'itération : objectif utilisateur, expérience
joueur attendue, fichier(s) concerné(s) (`spike3d-village.html` et/ou
`spike3d-planet2.html`), changements fonctionnels, changements visuels,
risques, critères d'acceptation, éléments explicitement hors périmètre.

Écris cette fiche dans `art/reviews/current-plan.md`. Ne modifie pas encore
le code.

## Phase B — Inspecter l'existant

Chaque planète est UN SEUL fichier HTML autonome (HTML + CSS + JS module,
Three.js par importmap CDN, zéro build, zéro TypeScript). Avant toute
modification, inspecte UNIQUEMENT ce qui est concerné par la demande dans le
fichier ciblé : le `<style>` (HUD DOM), la scène Three.js (géométries,
matériaux, lumières, caméra), la logique de jeu (déplacement, collisions
`obstacles[]`, dialogue, mini-jeu du pont), les hooks de debug
(`window.__spikeDebug`).

Réutilise les fonctions déjà présentes (`toon()`, `addOutline()`,
`addGlowOutline()`, `scatter()`, `makeSignSprite()`, etc.) — ne duplique pas.

## Phase C — Assets (cas rare)

Le jeu est **100 % procédural** (géométries Three.js + toon shading + contours
peints) : pas de pipeline d'assets à gérer dans le cas général. N'introduis
une image/texture générée que si le besoin l'exige explicitement (ex. une
icône UI illisible en CSS pur) — voir `asset-rules.md` pour le générateur
disponible mais actuellement inutilisé. Ne jamais présenter un ajout d'image
comme la solution par défaut ; ne jamais prétendre qu'un asset a été généré
si aucun générateur n'a effectivement tourné.

**Exception** : si Camille fournit une planche/image de référence à
reproduire fidèlement, suivre `board-fidelity.md` à la place de cette
phase par défaut (construction en passes, point d'arrêt avant génération
d'icônes en série, vérification de transparence par calcul, comparaison
GPT vision).

## Phase D — Implémenter

Seulement les changements nécessaires. Contraintes : Three.js pur (pas de
framework, pas de bundler, pas de TypeScript), style toon existant respecté
(`toon()`/`addOutline()` pour tout objet de décor, palette bonbon — voir
`asset-rules.md`), aucune régression fonctionnelle, aucun élément temporaire
visible (capsule de debug, etc.), performance (instancer les objets répétés
nombreux via `THREE.InstancedMesh`, cf. l'herbe/les fleurs), caméra
orthographique isométrique **inchangée sauf demande explicite**, aucun voile
plein écran, HUD DOM discret et proportionné (règles de `visual-quality.md`),
aucun élément (DOM ou sprite 3D) partiellement hors cadre à l'angle de
caméra par défaut.

## Phase E — Lancer

`npm run dev` (Vite, port par défaut 5173 — détecter le port réel dans la
sortie). Aucun build : les fichiers `public/*.html` sont servis tels quels.
Conserve le serveur actif le temps de la capture.

## Phase F — Capturer le jeu

`GAME_URL="http://localhost:<port>/spike3d-village.html" npm run capture`
(adapter l'URL au fichier concerné — la racine `/` fait un simple renvoi et
peut ne pas se stabiliser à temps pour la capture). Écrit
`art/reviews/latest.png` et `art/reviews/browser-errors.json`.

**Piège gravé** : en capture headless (Playwright/SwiftShader = rendu
logiciel), le FPS mesuré n'a AUCUN rapport avec le FPS réel (quelques FPS
structurels de fond) et le `dt` de la boucle de jeu est clampé — ne JAMAIS
juger la fluidité sur cette base, ni conclure à un bug sur un test avec délai
court après une interaction simulée. Le FPS ne se valide qu'en navigateur
réel, par Camille.

## Phase G — Revue visuelle

UNE SEULE revue par itération : lance le sous-agent `eluminia-visual-reviewer`
(il lit l'image et écrit `art/reviews/latest-review.md`) et appuie-toi sur son
rapport — ne relis PAS `latest.png` toi-même. Un chargement sans erreur ne
suffit jamais : la revue visuelle est obligatoire, mais jamais en double
(budget d'UN sous-agent par tâche, cf. `CLAUDE.md`).

Seulement si le sous-agent est indisponible OU si le budget d'un sous-agent
par tâche est déjà consommé dans cette itération : analyse toi-même l'image
(outil Read, une seule lecture) selon les points de `visual-quality.md` et
écris la revue dans `art/reviews/latest-review.md` au format :

```
# Résultat
- Conforme : oui/non
- Chargement : succès/échec
- Amélioration visuelle visible : oui/non
- Régressions : liste
# Défauts bloquants
# Défauts majeurs
# Défauts mineurs
# Corrections à appliquer
```

## Phase H — Corriger automatiquement

Si un défaut bloquant listé dans `visual-quality.md` est détecté : corrige,
recapture, réanalyse. Maximum 1 cycle complet de correction automatique.
S'il reste des défauts bloquants après ce cycle : les lister dans le rapport
final et S'ARRÊTER — Camille décidera de la suite. Ne prétends JAMAIS qu'un
problème est corrigé sans l'avoir vérifié sur une nouvelle capture.

Un défaut trouvé mais HORS PÉRIMÈTRE de la demande initiale (ex. un bug
préexistant sans lien avec la fonctionnalité touchée) n'est PAS corrigé
silencieusement : il est signalé dans le rapport pour décision de Camille,
même s'il est bloquant au sens de `visual-quality.md`.

## Phase I — Historique

Après chaque itération : copie `current-plan.md` et `latest-review.md` dans
`art/reviews/history/` préfixés d'un timestamp (`yyyyMMdd-HHmmss-`), conserve
`latest.png`, ne supprime aucune revue ancienne.

## Phase J — Rapport final

Réponds avec uniquement : 1. résumé de l'itération ; 2. fichiers modifiés ;
3. résultat de la capture/revue ; 4. nombre de cycles de correction ;
5. principaux défauts corrigés ; 6. limites restantes (y compris tout défaut
hors périmètre signalé) ; 7. chemin de la capture finale.

Aucun commentaire vague (« rendu professionnel ») : uniquement des constats
vérifiés.
