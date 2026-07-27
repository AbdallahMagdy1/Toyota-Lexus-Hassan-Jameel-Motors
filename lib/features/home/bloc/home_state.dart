part of 'home_cubit.dart';

enum HomeStatus { loading, ready, error }

final class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.feed = const HomeFeed(),
    this.heroIndex = 0,
    this.vehicleCategory,
    this.partsCategoryId,
    this.partsSubCategoryId,
    this.parts = const [],
    this.partsLoading = false,
    this.protectionGroup,
    this.protectionModel,
    this.protectionServices = const [],
    this.protectionService,
    this.protectionLoading = false,
  });

  final HomeStatus status;
  final HomeFeed feed;
  final int heroIndex;
  final String? vehicleCategory; // null = ALL
  final String? partsCategoryId; // null = featured (in-stock, all cats)
  final String? partsSubCategoryId;
  final List<SparePart> parts;
  final bool partsLoading;
  final ProtectionGroup? protectionGroup;
  final ProtectionModel? protectionModel;
  final List<ProtectionService> protectionServices;
  final ProtectionService? protectionService;
  final bool protectionLoading;

  List<HomeOffer> get heroOffers =>
      [...feed.vehicleOffers, ...feed.maintenanceOffers];

  List<SliderVehicle> get filteredVehicles => vehicleCategory == null
      ? feed.vehicles
      : feed.vehicles.where((v) => v.category == vehicleCategory).toList();

  List<PartCategory> get partsSubCategories =>
      feed.subCategoriesOf(partsCategoryId);

  List<ProtectionModel> get protectionModels => feed.modelsOf(protectionGroup);

  HomeState copyWith({
    HomeStatus? status,
    HomeFeed? feed,
    int? heroIndex,
    String? vehicleCategory,
    bool clearVehicleCategory = false,
    String? partsCategoryId,
    bool clearPartsCategory = false,
    String? partsSubCategoryId,
    bool clearPartsSubCategory = false,
    List<SparePart>? parts,
    bool? partsLoading,
    ProtectionGroup? protectionGroup,
    ProtectionModel? protectionModel,
    bool clearProtectionModel = false,
    List<ProtectionService>? protectionServices,
    ProtectionService? protectionService,
    bool clearProtectionService = false,
    bool? protectionLoading,
  }) =>
      HomeState(
        status: status ?? this.status,
        feed: feed ?? this.feed,
        heroIndex: heroIndex ?? this.heroIndex,
        vehicleCategory:
            clearVehicleCategory ? null : (vehicleCategory ?? this.vehicleCategory),
        partsCategoryId:
            clearPartsCategory ? null : (partsCategoryId ?? this.partsCategoryId),
        partsSubCategoryId: clearPartsSubCategory
            ? null
            : (partsSubCategoryId ?? this.partsSubCategoryId),
        parts: parts ?? this.parts,
        partsLoading: partsLoading ?? this.partsLoading,
        protectionGroup: protectionGroup ?? this.protectionGroup,
        protectionModel:
            clearProtectionModel ? null : (protectionModel ?? this.protectionModel),
        protectionServices: protectionServices ?? this.protectionServices,
        protectionService: clearProtectionService
            ? null
            : (protectionService ?? this.protectionService),
        protectionLoading: protectionLoading ?? this.protectionLoading,
      );

  @override
  List<Object?> get props => [
        status,
        feed,
        heroIndex,
        vehicleCategory,
        partsCategoryId,
        partsSubCategoryId,
        parts,
        partsLoading,
        protectionGroup,
        protectionModel,
        protectionServices,
        protectionService,
        protectionLoading,
      ];
}
