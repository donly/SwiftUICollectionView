//
//  ContentView.swift
//  SwiftUICollectionView
//
//  Created by Don on 26/10/2020.
//

import SwiftUI

struct ContentView: View {
     var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    var body: some View {
        GeometryReader { proxy in
            GridView(self.numbers, proxy: proxy) { number in
                Image(systemName: "\(number).square.fill")
                .resizable()
                .scaledToFill()
            }
        }
    }
}
struct GridView<CellView: View>: UIViewRepresentable {
    let cellView: (Int) -> CellView
    let proxy: GeometryProxy
    var numbers: [Int]
    init(_ numbers: [Int], proxy: GeometryProxy, @ViewBuilder cellView: @escaping (Int) -> CellView) {
        self.proxy = proxy
        self.cellView = cellView
        self.numbers = numbers
    }
    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .gray
        collectionView.register(GridCellView.self, forCellWithReuseIdentifier: "CELL")

        collectionView.dragDelegate = context.coordinator //to drag cell view
        collectionView.dropDelegate = context.coordinator //to drop cell view

        collectionView.dragInteractionEnabled = true
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.contentInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return collectionView
    }
    func updateUIView(_ uiView: UICollectionView, context: Context) { }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
        var parent: GridView
        init(_ parent: GridView) {
            self.parent = parent
        }
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return parent.numbers.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath) as! GridCellView
            cell.backgroundColor = .clear
            cell.cellView.rootView = AnyView(parent.cellView(parent.numbers[indexPath.row]).fixedSize())
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: ((parent.proxy.frame(in: .global).width - 8) / 4), height: ((parent.proxy.frame(in: .global).width - 8) / 4))
        }

        //Provides the initial set of items (if any) to drag.
        func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
            let item = self.parent.numbers[indexPath.row]
            let itemProvider = NSItemProvider(object: String(item) as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            return [dragItem]
        }

        //Tells your delegate that the position of the dragged data over the collection view changed.
        func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
            if collectionView.hasActiveDrag {
                print("collectionView.hasActiveDrag=true")
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
            print("collectionView.hasActiveDrag=false")
            return UICollectionViewDropProposal(operation: .forbidden)
        }

        //Tells your delegate to incorporate the drop data into the collection view.
        func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
            var destinationIndexPath: IndexPath
            if let indexPath = coordinator.destinationIndexPath {
                destinationIndexPath = indexPath
            } else {
                let row = collectionView.numberOfItems(inSection: 0)
                destinationIndexPath = IndexPath(item: row - 1, section: 0)
            }
            if coordinator.proposal.operation == .move {
                self.reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
            }
        }
        private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
            if let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath {
                collectionView.performBatchUpdates({
                    self.parent.numbers.remove(at: sourceIndexPath.item)
                    self.parent.numbers.insert(item.dragItem.localObject as! Int, at: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                }, completion: nil)
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            }
        }
    }
}
class GridCellView: UICollectionViewCell {
    public var cellView = UIHostingController(rootView: AnyView(EmptyView()))
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    private func configure() {
        contentView.addSubview(cellView.view)
        cellView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cellView.view.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 5),
            cellView.view.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -5),
            cellView.view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            cellView.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
        ])
        cellView.view.layer.masksToBounds = true
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
