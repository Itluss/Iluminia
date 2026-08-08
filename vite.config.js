// Configuration minimale — le projet reste "zéro build" (public/*.html
// servi tel quel, aucune transformation). Seul réglage nécessaire :
// autoriser les hôtes externes (tunnel Cloudflare) à atteindre le serveur
// de dev pour les tests sur mobile, sans modifier le pare-feu/réseau local.
export default {
  server: {
    host: true,
    allowedHosts: true,
  },
};
