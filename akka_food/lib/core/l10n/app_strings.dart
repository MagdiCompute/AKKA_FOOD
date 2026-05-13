/// French strings for the AKKA Food app.
///
/// All user-facing text is centralized here for easy maintenance
/// and future multi-language support.
abstract final class S {
  // ── App ──────────────────────────────────────────────────────────────────
  static const appName = 'AKKA Food';
  static const appTagline = 'Savourez le meilleur du Mali';

  // ── Navigation ───────────────────────────────────────────────────────────
  static const navMenu = 'Menu';
  static const navCart = 'Panier';
  static const navRanks = 'Classement';
  static const navProfile = 'Profil';
  static const navAdmin = 'Admin';

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const loginTitle = 'Connexion';
  static const loginSubtitle = 'Bienvenue sur AKKA Food';
  static const loginEmail = 'Adresse e-mail';
  static const loginPassword = 'Mot de passe';
  static const loginButton = 'Se connecter';
  static const loginForgotPassword = 'Mot de passe oublié ?';
  static const loginNoAccount = 'Pas encore de compte ?';
  static const loginSignUp = 'Créer un compte';
  static const loginWithGoogle = 'Continuer avec Google';
  static const loginWithFacebook = 'Continuer avec Facebook';
  static const loginOr = 'ou';

  static const signUpTitle = 'Créer un compte';
  static const signUpName = 'Nom complet';
  static const signUpEmail = 'Adresse e-mail';
  static const signUpPassword = 'Mot de passe';
  static const signUpConfirmPassword = 'Confirmer le mot de passe';
  static const signUpButton = 'S\'inscrire';
  static const signUpHaveAccount = 'Déjà un compte ?';
  static const signUpLogin = 'Se connecter';

  static const forgotPasswordTitle = 'Mot de passe oublié';
  static const forgotPasswordSubtitle =
      'Entrez votre e-mail pour recevoir un lien de réinitialisation';
  static const forgotPasswordButton = 'Envoyer le lien';
  static const forgotPasswordSuccess =
      'Un e-mail de réinitialisation a été envoyé.';

  static const otpTitle = 'Vérification';
  static const otpSubtitle = 'Entrez le code envoyé à';
  static const otpVerify = 'Vérifier';
  static const otpResend = 'Renvoyer le code';

  // ── Catalog ──────────────────────────────────────────────────────────────
  static const catalogTitle = 'Menu';
  static const catalogSearch = 'Rechercher un plat…';
  static const catalogFilter = 'Filtrer';
  static const catalogSort = 'Trier';
  static const catalogAllMeals = 'Tous les plats';
  static const catalogFilteredMeals = 'Plats filtrés';
  static const catalogNoMeals = 'Aucun plat disponible';
  static const catalogNoMatch = 'Aucun plat ne correspond à vos filtres';
  static const catalogClearFilters = 'Effacer les filtres';
  static const catalogFeatured = 'À la une';
  static const catalogRecommended = 'Recommandé pour vous';

  // ── Meal Detail ──────────────────────────────────────────────────────────
  static const mealDetailTitle = 'Détail du plat';
  static const mealDetailAddToCart = 'Ajouter au panier';
  static const mealDetailUnavailable = 'Indisponible';
  static const mealDetailAvailable = 'Disponible';
  static const mealDetailNutrition = 'Informations nutritionnelles';
  static const mealDetailCalories = 'Calories';
  static const mealDetailProtein = 'Protéines';
  static const mealDetailCarbs = 'Glucides';
  static const mealDetailFat = 'Lipides';
  static const mealDetailAddedToCart = 'Ajouté au panier';

  // ── Cart ─────────────────────────────────────────────────────────────────
  static const cartTitle = 'Mon Panier';
  static const cartEmpty = 'Votre panier est vide';
  static const cartEmptySubtitle = 'Ajoutez des plats délicieux pour commencer.';
  static const cartBrowseMenu = 'Parcourir le menu';
  static const cartCheckout = 'Commander';
  static const cartClear = 'Vider le panier';
  static const cartClearConfirm =
      'Tous les articles seront supprimés. Cette action est irréversible.';
  static const cartClearTitle = 'Vider le panier ?';
  static const cartSubtotal = 'Sous-total';
  static const cartDeliveryFee = 'Frais de livraison';
  static const cartCoinDiscount = 'Réduction coins';
  static const cartTotal = 'Total';
  static const cartCancel = 'Annuler';
  static const cartConfirm = 'Confirmer';

  // ── Delivery ─────────────────────────────────────────────────────────────
  static const deliveryOption = 'Livraison';
  static const pickupOption = 'À emporter';
  static const deliverySelectAddress = 'Sélectionner une adresse de livraison';
  static const deliveryNoAddress = 'Veuillez sélectionner une adresse de livraison';

  // ── Coins ────────────────────────────────────────────────────────────────
  static const coinsTitle = 'Mes Coins';
  static const coinsBalance = 'Solde';
  static const coinsHistory = 'Historique';
  static const coinsRedeem = 'Utiliser mes coins';
  static const coinsApplied = 'Coins appliqués';
  static const coinsRemove = 'Retirer';

  // ── Profile ──────────────────────────────────────────────────────────────
  static const profileTitle = 'Mon Profil';
  static const profileEdit = 'Modifier le profil';
  static const profileAddresses = 'Mes adresses';
  static const profileOrders = 'Historique des commandes';
  static const profileCoins = 'Mes coins';
  static const profileNotifications = 'Notifications';
  static const profileSignOut = 'Se déconnecter';
  static const profileDeactivate = 'Désactiver le compte';
  static const profileDelete = 'Supprimer le compte';
  static const profileAccountManagement = 'Gestion du compte';
  static const profileAccount = 'Compte';

  // ── Edit Profile ─────────────────────────────────────────────────────────
  static const editProfileTitle = 'Modifier le profil';
  static const editProfileName = 'Nom complet';
  static const editProfileEmail = 'Adresse e-mail';
  static const editProfilePhone = 'Numéro de téléphone';
  static const editProfileSave = 'Enregistrer';
  static const editProfileSuccess = 'Profil mis à jour avec succès.';

  // ── Addresses ────────────────────────────────────────────────────────────
  static const addressTitle = 'Mes adresses';
  static const addressAdd = 'Ajouter une adresse';
  static const addressEdit = 'Modifier l\'adresse';
  static const addressLabel = 'Libellé';
  static const addressStreet = 'Adresse';
  static const addressCity = 'Ville';
  static const addressCoordinates = 'Coordonnées (optionnel)';
  static const addressLatitude = 'Latitude';
  static const addressLongitude = 'Longitude';
  static const addressPickOnMap = 'Choisir sur la carte';
  static const addressSave = 'Enregistrer';
  static const addressDefault = 'Par défaut';

  // ── Orders ───────────────────────────────────────────────────────────────
  static const ordersTitle = 'Mes commandes';
  static const ordersEmpty = 'Aucune commande pour le moment';
  static const orderDetail = 'Détail de la commande';
  static const orderTracking = 'Suivi de la commande';

  // ── Leaderboard ──────────────────────────────────────────────────────────
  static const leaderboardTitle = 'Classement';
  static const leaderboardAllTime = 'Tout le temps';
  static const leaderboardMonthly = 'Ce mois';
  static const leaderboardWeekly = 'Cette semaine';
  static const leaderboardEmpty = 'Aucun classement pour le moment';
  static const leaderboardEmptySubtitle =
      'Soyez le premier à passer une commande !';
  static const leaderboardYourPosition = '• • •  Votre position  • • •';

  // ── Payment ──────────────────────────────────────────────────────────────
  static const paymentTitle = 'Paiement';
  static const paymentProcessing = 'Traitement en cours…';
  static const paymentSuccess = 'Paiement réussi !';
  static const paymentFailed = 'Échec du paiement';
  static const paymentRetry = 'Réessayer';
  static const paymentCancel = 'Annuler le paiement';

  // ── Admin ────────────────────────────────────────────────────────────────
  static const adminTitle = 'Administration';
  static const adminMeals = 'Plats';
  static const adminCategories = 'Catégories';
  static const adminOrders = 'Commandes';
  static const adminUsers = 'Utilisateurs';
  static const adminAnalytics = 'Statistiques';
  static const adminNewMeal = 'Nouveau plat';
  static const adminEditMeal = 'Modifier le plat';
  static const adminNewCategory = 'Nouvelle catégorie';
  static const adminEditCategory = 'Modifier la catégorie';
  static const adminSave = 'Enregistrer';
  static const adminDelete = 'Supprimer';
  static const adminDeleteConfirm = 'Êtes-vous sûr de vouloir supprimer ?';

  // ── Common ───────────────────────────────────────────────────────────────
  static const retry = 'Réessayer';
  static const cancel = 'Annuler';
  static const confirm = 'Confirmer';
  static const save = 'Enregistrer';
  static const delete = 'Supprimer';
  static const edit = 'Modifier';
  static const close = 'Fermer';
  static const loading = 'Chargement…';
  static const error = 'Une erreur est survenue';
  static const success = 'Succès';
  static const noData = 'Aucune donnée';
  static const offline = 'Vous êtes hors ligne. Données en cache affichées.';
}
