import SwiftUI

// MARK: - Tile Model
struct Tile: Identifiable {
    let id = UUID()
    let color: Color
    var isRevealed = false
    var isMatched = false
    var isBlocked = false
}

// MARK: - Game Levels
enum GameLevel: String {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var gridSize: Int {
        switch self {
        case .easy: return 3
        case .medium: return 5
        case .hard: return 7
        }
    }

    var timeLimit: Int {
        switch self {
        case .easy: return 30
        case .medium: return 45
        case .hard: return 60
        }
    }
}

// MARK: - Home Screen
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Pixel Palette")
                    .font(.largeTitle)
                    .bold()

                levelButton("Easy", .easy, color: .green)
                levelButton("Medium", .medium, color: .orange)
                levelButton("Hard", .hard, color: .red)
            }
            .padding()
        }
    }

    func levelButton(_ title: String, _ level: GameLevel, color: Color) -> some View {
        NavigationLink {
            GameFlowView(level: level)
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color.gradient)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
    }
}

// MARK: - GAME FLOW CONTROLLER
struct GameFlowView: View {
    let level: GameLevel
    @State private var goToAnimals = false

    var body: some View {
        VStack {
            NavigationLink(
                destination: AnimalGameView(),
                isActive: $goToAnimals
            ) { EmptyView() }

            GameView(level: level) {
                goToAnimals = true
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Color Matching Game
struct GameView: View {
    let level: GameLevel
    let onFinish: () -> Void

    @State private var tiles: [Tile] = []
    @State private var selectedTiles: [Int] = []
    @State private var score = 0
    @State private var moves = 0
    @State private var isChecking = false

    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var hasFinished = false

    let allColors: [Color] = [
        .red, .orange, .yellow, .green,
        .mint, .cyan, .blue, .indigo,
        .purple, .pink
    ]

    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8),
              count: level.gridSize)
    }

    var body: some View {
        VStack {
            HStack {
                Text("⏱ \(timeRemaining)s")
                Spacer()
                Text("Score: \(score)")
                Spacer()
                Text("Moves: \(moves)")
            }
            .padding()

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(tiles.indices, id: \.self) { index in
                    TileView(tile: tiles[index])
                        .onTapGesture { tileTapped(index) }
                }
            }
            .padding()
        }
        .onAppear { setupGame() }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Game Logic
    func setupGame() {
        timer?.invalidate()
        hasFinished = false

        let totalTiles = level.gridSize * level.gridSize
        let pairCount = totalTiles / 2

        var newTiles: [Tile] = []
        for i in 0..<pairCount {
            let color = allColors[i % allColors.count]
            newTiles.append(Tile(color: color))
            newTiles.append(Tile(color: color))
        }

        if totalTiles % 2 != 0 {
            newTiles.append(Tile(color: .black, isBlocked: true))
        }

        newTiles.shuffle()
        tiles = newTiles
        selectedTiles.removeAll()
        score = 0
        moves = 0
        timeRemaining = level.timeLimit
        startTimer()
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard !hasFinished else { return }

            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                finishGame()
            }
        }
    }

    func tileTapped(_ index: Int) {
        guard !isChecking,
              !tiles[index].isMatched,
              !tiles[index].isRevealed,
              !hasFinished else { return }

        if tiles[index].isBlocked {
            tiles[index].isRevealed = true
            return
        }

        tiles[index].isRevealed = true
        selectedTiles.append(index)

        if selectedTiles.count == 2 {
            isChecking = true
            moves += 1
            checkMatch()
        }
    }

    func checkMatch() {
        let a = selectedTiles[0]
        let b = selectedTiles[1]

        if tiles[a].color == tiles[b].color {
            tiles[a].isMatched = true
            tiles[b].isMatched = true
            score += 10
            finishTurn()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                tiles[a].isRevealed = false
                tiles[b].isRevealed = false
                finishTurn()
            }
        }
    }

    func finishTurn() {
        selectedTiles.removeAll()
        isChecking = false

        if tiles.allSatisfy({ $0.isMatched || $0.isBlocked }) {
            finishGame()
        }
    }

    func finishGame() {
        guard !hasFinished else { return }
        hasFinished = true
        timer?.invalidate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onFinish()
        }
    }
}

// MARK: - Tile UI
struct TileView: View {
    let tile: Tile

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(tile.isRevealed
                      ? (tile.isBlocked ? .black : tile.color)
                      : Color.gray.opacity(0.6))

            if tile.isBlocked && tile.isRevealed {
                Image(systemName: "nosign")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Animal Matching Game
struct AnimalGameView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("🐶 Animal Matching Game")
                .font(.largeTitle)
                .bold()

            Text("Automatically reached after color game")

            Text("🎉 READY TO PLAY 🎉")
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
