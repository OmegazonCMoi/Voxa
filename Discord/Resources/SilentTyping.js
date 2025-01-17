/*
 * Creator : OmegazonCMoi :)
 */

(function () {
  // Patch pour bloquer l'envoi des requêtes de saisie
  const originalDispatch = window.dispatch; // Sauvegarde de la fonction dispatch originale

  // Remplacer la fonction `dispatch` pour bloquer les requêtes de saisie
  window.dispatch = function (action) {
    if (action.type === "TYPING_START_LOCAL" && window.silentTypingEnabled) {
      console.log(
        "Silent Typing is enabled. No typing notification will be sent."
      );
      return; // Bloque l'envoi de la requête
    }
    // Appeler la fonction dispatch originale si Silent Typing n'est pas activé
    originalDispatch.apply(this, arguments);
  };

  // Flag pour activer ou désactiver Silent Typing
  window.silentTypingEnabled = true; // Mettre à `false` pour activer les notifications de saisie
})();
