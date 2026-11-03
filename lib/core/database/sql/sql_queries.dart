// Barrel temporaire des requêtes SQL.
import 'auth_queries.dart';
import 'catalogue_queries.dart';
import 'client_queries.dart';
import 'contrat_queries.dart';
import 'facture_queries.dart';
import 'historique_queries.dart';
import 'notification_queries.dart';
import 'planning_queries.dart';

export 'auth_queries.dart';
export 'client_queries.dart';
export 'contrat_queries.dart';
export 'facture_queries.dart';
export 'planning_queries.dart';
export 'historique_queries.dart';
export 'catalogue_queries.dart';
export 'notification_queries.dart';

class SqlQueries {
  static const String login = AuthQueries.login;

  static const String checkUsername = AuthQueries.checkUsername;

  static const String getUserById = AuthQueries.getUserById;

  static const String updateUserProfile = AuthQueries.updateUserProfile;

  static const String getAllAccounts = AuthQueries.getAllAccounts;

  static const String deleteAccount = AuthQueries.deleteAccount;

  static const String getClientsPaginated = ClientQueries.getClientsPaginated;

  static const String getClientById = ClientQueries.getClientById;

  static const String createClient = ClientQueries.createClient;

  static const String updateClient = ClientQueries.updateClient;

  static const String searchClients = ClientQueries.searchClients;

  static const String checkEmail = ClientQueries.checkEmail;

  static const String getCategories = ClientQueries.getCategories;

  static const String getAllClientsBasic = ClientQueries.getAllClientsBasic;

  static const String getContratsPaginated =
      ContratQueries.getContratsPaginated;

  static const String getContratById = ContratQueries.getContratById;

  static const String createContrat = ContratQueries.createContrat;

  static const String updateContrat = ContratQueries.updateContrat;

  static const String deleteContrat = ContratQueries.deleteContrat;

  static const String searchContrats = ContratQueries.searchContrats;

  static const String createTraitement = ContratQueries.createTraitement;

  static const String abrogateContrat = ContratQueries.abrogateContrat;

  static const String getTreatmentsByContrat =
      ContratQueries.getTreatmentsByContrat;

  static const String countTreatmentsByContrat =
      ContratQueries.countTreatmentsByContrat;

  static const String getTraitementsDetailedByContrat =
      ContratQueries.getTraitementsDetailedByContrat;

  static const String getFuturePlanningsByTreatment =
      ContratQueries.getFuturePlanningsByTreatment;

  static const String deleteFuturePlanningDetailsByPlanning =
      ContratQueries.deleteFuturePlanningDetailsByPlanning;

  static const String getFacturesByContrat =
      FactureQueries.getFacturesByContrat;

  static const String getFacturesByClientDetailed =
      FactureQueries.getFacturesByClientDetailed;

  static const String getAllFacturesDetailed =
      FactureQueries.getAllFacturesDetailed;

  static const String countAllFactures = FactureQueries.countAllFactures;

  static const String getFacturesByPlanningDetail =
      FactureQueries.getFacturesByPlanningDetail;

  static const String getFacturesGroupedByTraitement =
      FactureQueries.getFacturesGroupedByTraitement;

  static const String getPriceHistory = FactureQueries.getPriceHistory;

  static const String updateFacturePrice = FactureQueries.updateFacturePrice;

  static const String markFactureAsPaid = FactureQueries.markFactureAsPaid;

  static const String updateFactureReference =
      FactureQueries.updateFactureReference;

  static const String massUpdateFutureFacturePrices =
      FactureQueries.massUpdateFutureFacturePrices;

  static const String getFactureAndTreatmentInfo =
      FactureQueries.getFactureAndTreatmentInfo;

  static const String getOtherFacturesByTreatmentFromDate =
      FactureQueries.getOtherFacturesByTreatmentFromDate;

  static const String createPriceHistoryEntry =
      FactureQueries.createPriceHistoryEntry;

  static const String createFacture = FactureQueries.createFacture;

  static const String createFactureWithMode =
      FactureQueries.createFactureWithMode;

  static const String checkFactureExistence =
      FactureQueries.checkFactureExistence;

  static const String createFactureComplete =
      FactureQueries.createFactureComplete;

  static const String updateFactureFull = FactureQueries.updateFactureFull;

  static const String updateFacturePaymentOnly =
      FactureQueries.updateFacturePaymentOnly;

  static const String deleteFacture = FactureQueries.deleteFacture;

  static const String getExportData = FactureQueries.getExportData;

  static const String getClientAxeByTreatment =
      PlanningQueries.getClientAxeByTreatment;

  static const String getPlanningByTreatment =
      PlanningQueries.getPlanningByTreatment;

  static const String countPlanningDetails =
      PlanningQueries.countPlanningDetails;

  static const String countPlanningDetailsByTreatment =
      PlanningQueries.countPlanningDetailsByTreatment;

  static const String countFacturesByTreatment =
      PlanningQueries.countFacturesByTreatment;

  static const String countRemarquesByTreatment =
      PlanningQueries.countRemarquesByTreatment;

  static const String countHistoriqueByTreatment =
      PlanningQueries.countHistoriqueByTreatment;

  static const String sumMontantByTreatment =
      PlanningQueries.sumMontantByTreatment;

  static const String getRedondanceByTreatment =
      PlanningQueries.getRedondanceByTreatment;

  static const String getTreatmentIdByType =
      PlanningQueries.getTreatmentIdByType;

  static const String insertPlanningDetail =
      PlanningQueries.insertPlanningDetail;

  static const String getPlanningDetailsByPlanningIdOrdered =
      PlanningQueries.getPlanningDetailsByPlanningIdOrdered;

  static const String checkExistingPlanningDetail =
      PlanningQueries.checkExistingPlanningDetail;

  static const String insertPlanningDetailWithStatut =
      PlanningQueries.insertPlanningDetailWithStatut;

  static const String updatePlanningDetailFacture =
      PlanningQueries.updatePlanningDetailFacture;

  static const String getPlanningDetailsByPlanningId =
      PlanningQueries.getPlanningDetailsByPlanningId;

  static const String updatePlanningDetailStatut =
      PlanningQueries.updatePlanningDetailStatut;

  static const String deletePlanningDetail =
      PlanningQueries.deletePlanningDetail;

  static const String getAllPlanningDetails =
      PlanningQueries.getAllPlanningDetails;

  static const String getPlanningDetailCompleteById =
      PlanningQueries.getPlanningDetailCompleteById;

  static const String getCurrentMonthTreatmentsComplete =
      PlanningQueries.getCurrentMonthTreatmentsComplete;

  static const String getUpcomingTreatmentsComplete =
      PlanningQueries.getUpcomingTreatmentsComplete;

  static const String getAllTreatmentsComplete =
      PlanningQueries.getAllTreatmentsComplete;

  static const String getAllTreatmentsPaginated =
      PlanningQueries.getAllTreatmentsPaginated;

  static const String countAllTreatments = PlanningQueries.countAllTreatments;

  static const String countTreatmentsByCategory =
      PlanningQueries.countTreatmentsByCategory;

  static const String getTreatmentsByMonthAndClientBase =
      PlanningQueries.getTreatmentsByMonthAndClientBase;

  static const String getDistinctTreatmentTypes =
      PlanningQueries.getDistinctTreatmentTypes;

  static const String getDistinctTreatmentTypesByClient =
      PlanningQueries.getDistinctTreatmentTypesByClient;

  static const String createPlanning = PlanningQueries.createPlanning;

  static const String checkPlanningExistence =
      PlanningQueries.checkPlanningExistence;

  static const String getAllSignalements = PlanningQueries.getAllSignalements;

  static const String createSignalement = PlanningQueries.createSignalement;

  static const String updatePlanningDate = PlanningQueries.updatePlanningDate;

  static const String createRemarque = PlanningQueries.createRemarque;

  static const String getClientIdFromPlanningDetail =
      PlanningQueries.getClientIdFromPlanningDetail;

  static const String getAllRemarquesDetailed =
      PlanningQueries.getAllRemarquesDetailed;

  static const String getRemarquesByPlanningDetail =
      PlanningQueries.getRemarquesByPlanningDetail;

  static const String updateRemarqueBasic = PlanningQueries.updateRemarqueBasic;

  static const String deleteRemarque = PlanningQueries.deleteRemarque;

  static const String getAllHistoriqueDetailed =
      HistoriqueQueries.getAllHistoriqueDetailed;

  static const String getHistoriqueByCategory =
      HistoriqueQueries.getHistoriqueByCategory;

  static const String getHistoriqueByClient =
      HistoriqueQueries.getHistoriqueByClient;

  static const String getHistoriqueByDateRange =
      HistoriqueQueries.getHistoriqueByDateRange;

  static const String createHistoriqueEvent =
      HistoriqueQueries.createHistoriqueEvent;

  static const String searchHistorique = HistoriqueQueries.searchHistorique;

  static const String deleteOldHistorique =
      HistoriqueQueries.deleteOldHistorique;

  static const String getAllTypeTraitements =
      CatalogueQueries.getAllTypeTraitements;

  static const String getAllTypeTraitementsForAdmin =
      CatalogueQueries.getAllTypeTraitementsForAdmin;

  static const String getAllTraitementCategories =
      CatalogueQueries.getAllTraitementCategories;

  static const String getAllTraitementCategoriesForAdmin =
      CatalogueQueries.getAllTraitementCategoriesForAdmin;

  static const String createTraitementCategory =
      CatalogueQueries.createTraitementCategory;

  static const String createTypeTraitement =
      CatalogueQueries.createTypeTraitement;

  static const String setTypeTraitementVisibility =
      CatalogueQueries.setTypeTraitementVisibility;

  static const String setCategoryVisibility =
      CatalogueQueries.setCategoryVisibility;

  static const String setTreatmentsVisibilityByCategory =
      CatalogueQueries.setTreatmentsVisibilityByCategory;

  static const String getNextDayTreatmentsDetailed =
      NotificationQueries.getNextDayTreatmentsDetailed;

  static const String getNextDayTreatmentsWithDetails =
      NotificationQueries.getNextDayTreatmentsWithDetails;

  static const String countTodayTreatments =
      NotificationQueries.countTodayTreatments;
}
