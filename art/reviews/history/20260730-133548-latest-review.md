# Résultat
- Conforme : oui
- Build : succès (tsc strict + Vite), 0 erreur navigateur, contrôles
  automatiques (visual-check) tous verts
- Amélioration visuelle visible : oui — décor diorama B2-clean (Banana 2K)
  en jeu, natif ×1, net et vif, fidèle à ref-village-diorama.png ; monde
  agrandi 2528×1696 ; héros 116 px / Lina 110 px / renard 64 px à l'échelle
  des portes ; ancrage au sol et ombres corrects ; HUD complet
- Régressions : aucune détectée (plaque de nom, boutons Quêtes/Inventaire/
  Carte, barre Niv/XP/monnaies, hint d'interaction câblé, spawns dans la
  zone praticable)

# Défauts bloquants
- Aucun après 2 cycles de correction :
  1. Couture rectangulaire de l'occlusion fontaine → rai de lumière passé
     au-dessus de la découpe (depth 1150 > 1110). Vérifié sur recapture.
  2. Boîte claire du splash additif sur l'orbe → alpha 0,5 / échelle 0,95.
     Vérifié sur recapture zoomée (plus de rectangle visible).

# Complément (retours de Camille après tour de marche)
- « Héros traverse la fontaine » → collider étendu au pilier (1471,1075,
  250×210) : on ne marche plus sur le rebord du bassin. À re-tester en jeu.
- « Personnages très pixelisés » → cause : sprites du POC initial en 224×316
  style pixel-art. Régénérés en HD 1696×2528 via Banana (identité conservée,
  style peint de la bible) : hero-hd, hero-walk-hd, lina-hd, détourage
  runtime (fond gris uni). Vérifié sur crops zoomés de la capture : aucun
  halo, ombres correctes, échelle conforme. Test de cohérence Banana
  (étape 4) VALIDÉ : la pose de marche est le même personnage.

# Complément 2 (retours de Camille : fontaine, authenticité, relief UI)
- Fontaine : occlusion découpée SUPPRIMÉE définitivement (jamais propre sur
  un décor peint) ; fontaine entièrement solide (y 930-1180), aucun
  chevauchement possible. Vérifié.
- Personnages « posés là » : v2 générées — poses vivantes (héros contrapposto,
  Lina livre + salut), lumière dorée du village. Intégrées, vérifiées au zoom.
- Barre XP : panneau bois plaque-md + ombre portée + biseau, piste creusée,
  liseré doré. Monnaies pièce/gemme/étoile régénérées PLEINES (plus de
  découpes coupées). Vérifiée au zoom.
- Plaque du nom : ombre portée + biseau (relief). Vérifiée.
- Marqueur de quête : icône dédiée dorée, halo nettoyé (seuillage alpha).

# Défauts secondaires
- Barre d'interface haut-droite encore sombre/technique — conversion en bois
  illustré planifiée (spec Camille point 7), prochaine itération.
- Marche = alternance 2 poses (repos/marche) ; planche multi-poses possible
  maintenant que la cohérence Banana est prouvée.

# Corrections à appliquer
- (prochaines itérations, voir ci-dessus)

# Assets manquants
- Aucun.
