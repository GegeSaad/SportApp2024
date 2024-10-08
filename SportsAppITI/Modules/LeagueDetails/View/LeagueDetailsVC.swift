//
//  LeagueDetailsVC.swift
//  SportsAppITI
//
//  Created by Mahmoud on 8/12/24.
//

import UIKit

class LeagueDetailsVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private var imgNoData: UIImageView!
    @IBOutlet private var titleLbl: UILabel!
    @IBOutlet private var collectionLeagueDet: UICollectionView!
    @IBOutlet private var btnAddToFav: UIBarButtonItem!

    // MARK: - Properties
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    let viewModel = LeagueDetailsModel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureViewModel()
        viewModel.loadLatestEvents()
        viewModel.loadUpcomingEvents()
        viewModel.checkIfFavorite()
        updateFavoriteButton()
    }

    // MARK: - Setup Methods
    private func setupUI() {
        titleLbl.text = viewModel.leagueTitle.capitalized
        configureCollectionView()
        setupActivityIndicator()
    }

    private func configureViewModel() {
        viewModel.setUpActivityIndicator = { [weak self] in
            self?.activityIndicator.stopAnimating()
        }
        viewModel.updateFavoriteButton = { [weak self] in
            self?.updateFavoriteButton()
        }
        viewModel.reloadCollectionView = { [weak self] in
            self?.collectionLeagueDet.reloadData()
        }
        viewModel.showBackImage = { [weak self] hasErrors in
            self?.imgNoData.isHidden = !hasErrors
            self?.collectionLeagueDet.isHidden = hasErrors
            if hasErrors {
                self?.imgNoData.image = UIImage(named: "noResult")
            }
        }
    }

    private func setupActivityIndicator() {
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }

    private func configureCollectionView() {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self = self else { return nil }
            switch sectionIndex {
            case 0: return self.createUpcomingSection()
            case 1: return self.createLatestSection()
            default: return self.createTeamsSection()
            }
        }
        collectionLeagueDet.setCollectionViewLayout(layout, animated: true)
    }

    // MARK: - UI Update Methods
    private func updateFavoriteButton() {
        btnAddToFav.image = UIImage(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
    }

    // MARK: - Actions
    @IBAction private func addToFav(_ sender: Any) {
        viewModel.isFavorite.toggle()
        updateFavoriteButton()
        if viewModel.isFavorite {
            viewModel.saveLeague()
        } else {
            showRemoveFromFavoritesAlert()
        }
    }

    private func showRemoveFromFavoritesAlert() {
        let alert = UIAlertController(title: "Delete", message: "This league will be removed from favorites.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            self?.viewModel.isFavorite.toggle()
            self?.updateFavoriteButton()
        }))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { [weak self] _ in
            self?.viewModel.deleteLeague()
        }))
        present(alert, animated: true)
    }

    @IBAction private func btnBack(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionView Delegate
extension LeagueDetailsVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.cellForItem(at: indexPath)?.reuseIdentifier == "TeamsCVC" {
            performSegue(withIdentifier: "goToTeamVC", sender: indexPath.row)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToTeamVC",
           let teamsDetailsVC = segue.destination as? TeamsDetailsVC,
           let row = sender as? Int {
            teamsDetailsVC.viewModel.teamKey = viewModel.teams[row].teamKey
        }
    }
}

// MARK: - UICollectionView DataSource
extension LeagueDetailsVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private func createUpcomingSection() -> NSCollectionLayoutSection {
        return createSectionLayout(groupHeight: .absolute(UIScreen.main.bounds.height / 5), groupWidth: .fractionalWidth(0.85), orthogonalScrollingBehavior: .groupPagingCentered, headerEnabled: !viewModel.upcomingEvents.isEmpty)
    }

    private func createLatestSection() -> NSCollectionLayoutSection {
        return createSectionLayout(groupHeight: .absolute(UIScreen.main.bounds.height / 5), orthogonalScrollingBehavior: .none, headerEnabled: !viewModel.latestEvents.isEmpty)
    }

    private func createTeamsSection() -> NSCollectionLayoutSection {
        return createSectionLayout(groupHeight: .absolute(200), groupWidth: .absolute(150), orthogonalScrollingBehavior: .continuous, headerEnabled: !viewModel.teams.isEmpty)
    }

    private func createSectionLayout(groupHeight: NSCollectionLayoutDimension, groupWidth: NSCollectionLayoutDimension = .fractionalWidth(1), orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior, headerEnabled: Bool) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: groupWidth, heightDimension: groupHeight)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 12, trailing: 5)

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = orthogonalScrollingBehavior
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 5, bottom: 16, trailing: 5)

        section.visibleItemsInvalidationHandler = { items, offset, environment in
            items.forEach { item in
                let distanceFromCenter = abs((item.frame.midX - offset.x) - environment.container.contentSize.width / 2.0)
                let scale = max(1.0 - (distanceFromCenter / environment.container.contentSize.width), 0.8)
                item.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }

        if headerEnabled {
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(30))
            let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            section.boundarySupplementaryItems = [headerSupplementary]
        }
        return section
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return viewModel.upcomingEvents.count
        case 1: return viewModel.latestEvents.count
        default: return viewModel.teams.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0, 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LeaguesDetailsCVC", for: indexPath) as! LeaguesDetailsCVC
            let event = indexPath.section == 0 ? viewModel.upcomingEvents[indexPath.row] : viewModel.latestEvents[indexPath.row]
            cell.configure(with: event)
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeamsCVC", for: indexPath) as! TeamCollectionViewCell
            cell.configure(with: viewModel.teams[indexPath.row])
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "LeagueDSecHed", for: indexPath) as! LeagueSectionHeaderView
        header.sectionHeaderTitleLabel.text = ["Upcoming Events", "Latest Results", "Teams"][indexPath.section]
        return header
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.animateCellAppearance()
    }
}
