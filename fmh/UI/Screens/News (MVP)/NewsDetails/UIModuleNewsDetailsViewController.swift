//
//  UIModuleNewsDetailsViewController.swift
//  fmh
//
//  Created: 14.05.2022
//

import UIKit

class UIModuleNewsDetailsViewController: FMHUIViewControllerBase {
    
    var presenter: UIModuleNewsDetailsPresenterProtocol?
    private var filter = FilterNews()
    private var page = 0
    
    private lazy var newsPullRefresh: UIRefreshControl = {
        let refreshControl = FMHUIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        return refreshControl
    }()
    
    //ячейка для динамического определения размеров содержимого ячейки
    private let sizingCell = DetailsNewsCollectionViewCell()
    
    //MARK: - Создаем CollectionView для множественного выбора обязательно используем allowsMultipleSelection
    private lazy var detailsNewsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.register(DetailsNewsCollectionViewCell.self, forCellWithReuseIdentifier: "DetailsNewsCell")
        view.register(ActivityIndicatorCell.self, forCellWithReuseIdentifier: "ActivityIndicatorCell")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsVerticalScrollIndicator = true
        view.allowsMultipleSelection = true
        view.alwaysBounceVertical = true
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    private lazy var controlPanel: UIElementsControllPanel = {
        let colorTint = UIColor(red: 0.439, green: 0.439, blue: 0.439, alpha: 1)
        let view = UIElementsControllPanel(title: "Панель управления новостями", buttons: [
            .sorting(target: self, action: #selector(buttonSortedNewsAction),color: colorTint, isEnabled: true),
            .settings(target: self, action: #selector(buttonFilterNewsAction), color: colorTint, isEnabled: true),
            .plus(target: self, action: #selector(buttonAddNewsAction), color: colorTint, isEnabled: true)
        ])
        return view
    }()
    
    @objc private func refresh(sender: UIRefreshControl) {
        getNews()
        sender.endRefreshing()
    }
    
//MARK: - VC LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBackGround(name: "BackGround")
        setLayouts()
        detailsNewsCollectionView.refreshControl = newsPullRefresh
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getNews()
    }

    fileprivate func setBackGround(name: String) {
        if let image = UIImage(named: name) {
            self.view.backgroundColor  = UIColor(patternImage: image)
        }
    }
    
    //MARK: - Set layaouts views
    
    fileprivate func setLayouts() {
        
        /// Safe area margins
        let marginsView = self.view.layoutMarginsGuide
        
        /// Header with button
        self.view.addSubview(controlPanel)
        NSLayoutConstraint.activate([
            controlPanel.topAnchor.constraint(equalTo: marginsView.topAnchor),
            controlPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlPanel.heightAnchor.constraint(equalToConstant: 55)
        ])
        
        /// add collectionView
        self.view.addSubview(detailsNewsCollectionView)
        NSLayoutConstraint.activate([
            detailsNewsCollectionView.topAnchor.constraint(equalTo: controlPanel.bottomAnchor, constant: 0),
            detailsNewsCollectionView.bottomAnchor.constraint(equalTo: marginsView.bottomAnchor),
            detailsNewsCollectionView.leadingAnchor.constraint(equalTo: marginsView.leadingAnchor),
            detailsNewsCollectionView.trailingAnchor.constraint(equalTo: marginsView.trailingAnchor)
        ])
    }
    
    //MARK: -  Action button
    @objc func buttonAddNewsAction() {
        presenter?.tapOnAddNews()
    }
    
    @objc func buttonFilterNewsAction() {
        presenter?.tapOnFilter()
    }
    
    @objc func buttonSortedNewsAction() {

        filter.sorted.toggle()
        getNews()
    }
    
    @objc func editNewsAction(newsID: Int) {
        presenter?.tapOnAddNews()
    }
}

private extension UIModuleNewsDetailsViewController {
    func getNews() {
        page = 0
        presenter?.news.removeAll()
        presenter?.getAllNews(filter: filter, page: page)
    }
}

//MARK: - Extension for CollectionView

extension UIModuleNewsDetailsViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter?.news.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if presenter?.pages ?? 0 > page && indexPath.row == (presenter?.news.count ?? 0) - 1 && presenter?.pages != 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ActivityIndicatorCell", for: indexPath) as! ActivityIndicatorCell
            cell.activityIndicator.startAnimating()
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DetailsNewsCell", for: indexPath) as! DetailsNewsCollectionViewCell
            cell.delegate = self
            cell.index = indexPath.row
            
            if let item = presenter?.news[indexPath.row] {
                cell.configure(model: item)
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if presenter?.pages ?? 0 > page && indexPath.row == (presenter?.news.count ?? 0) - 1 && presenter?.pages != 1 {
            page += 1
            presenter?.getAllNews(filter: filter, page: page)
            print(presenter?.news.count)
        }
    }
}


//MARK: - Расчет динамической ячейки
extension UIModuleNewsDetailsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let isSelected = collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false

        if let item = presenter?.news[indexPath.row] {
            sizingCell.configure(model: item)
        }
        sizingCell.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: collectionView.bounds.width,
                height: 500))
        sizingCell.isSelected = isSelected
        sizingCell.setNeedsLayout()
        sizingCell.layoutIfNeeded()
        let size = sizingCell.systemLayoutSizeFitting(CGSize(width: collectionView.bounds.width, height: .greatestFiniteMagnitude), withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
}

extension UIModuleNewsDetailsViewController: UICollectionViewDelegate {
    //MARK: - Переопределение анимации сворачивания ячейки
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.performBatchUpdates(nil)
        return true
    }
    //MARK: - Переопределение анимации разворачивания ячейки
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        collectionView.performBatchUpdates(nil)
        return true
    }
}

//MARK: - action for ButtonCell
extension UIModuleNewsDetailsViewController: DetailsNewsCollectionViewCellDelegate {
    func editDetailsNewsCollectionViewCellDelegate(_ detailsCell: UICollectionViewCell, didClickEditButton index: Int) {
        
        guard let id = presenter?.news[index].id else { return }
        presenter?.tapOnEditNews(newsId: id, status: "editNews")
    }
    
    func deleteDetailsNewsCollectionViewCellDelegate(_ detailsCell: UICollectionViewCell, didClickDeleteButton index: Int) {
        self.showDeleteAlert(title: "Удаление", message: "Вы действительно хотите удалить новость?") { [weak self] in
            guard let self = self, let id = self.presenter?.news[index].id else { return }
            print("механизм удаление ячейки и данных из бека по индексу \(id)")
            self.presenter?.deleteNews(id: id, index: index)
        }
    }
}

//MARK: - DetailsNewsPresenterOutput

extension UIModuleNewsDetailsViewController: UIModuleNewsDetailsPresenterDelegate {
    
    func updatedNews() {
        detailsNewsCollectionView.reloadData()
    }
}
//MARK: - FilterNewsDelegate

extension UIModuleNewsDetailsViewController: FilterNewsDelegate {
    func filtering(filter: FilterNews?) {
        guard let filter = filter else { return }
        self.filter = filter
        getNews()
    }
}





