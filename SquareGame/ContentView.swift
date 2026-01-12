import SwiftUI

// MARK: - Tile Model
struct Tile: Identifiable {
    let id = UUID()
    let color: Color
    var isRevealed = false
    var isMatched = false
    var isBlocked = false   // 🚫 Blocked tile
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

// MARK: - Home Screen
struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.red, .orange, .yellow, .green, .blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Heading
                    Text("Pixel Palette")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.6), radius: 8, x: 4, y: 4)
                        .padding()
                        .overlay(
                            Text("Pixel Palette")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundColor(.white.opacity(0.2))
                                .blur(radius: 4)
                        )
                    
                    Text("Match the colours and avoid the block!")
                        .font(.title3)
                        .foregroundColor(Color.black.opacity(0.85))

                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Level Buttons
                    VStack(spacing: 20) {
                        levelButton("Easy", .easy, color: .green)
                        levelButton("Medium", .medium, color: .orange)
                        levelButton("Hard", .hard, color: .red)
                    }
                }
                .padding()
            }
        }
    }
    
    func levelButton(_ title: String, _ level: GameLevel, color: Color) -> some View {
        NavigationLink {
            GameView(level: level)
        } label: {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color.gradient)
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: color.opacity(0.6), radius: 6, x: 2, y: 2)
        }
    }
}

// MARK: - Game View
struct GameView: View {
    let level: GameLevel
    
    @State private var tiles: [Tile] = []
    @State private var selectedTiles: [Int] = []
    @State private var score = 0
    @State private var moves = 0
    @State private var isChecking = false
    @State private var gameCompleted = false
    
    let allColors: [Color] = [
        .red, .orange, .yellow, .green,
        .mint, .cyan, .blue, .indigo,
        .purple, .pink
    ]
    
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: level.gridSize)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            
            // Header
            VStack {
                Text(level.rawValue)
                    .font(.title2)
                    .bold()
                
                HStack {
                    Text("Score: \(score)")
                    Spacer()
                    Text("Moves: \(moves)")
                }
                .font(.headline)
                .padding(.horizontal)
            }
            
            // Tiles grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(tiles.indices, id: \.self) { index in
                    TileView(tile: tiles[index])
                        .onTapGesture { tileTapped(index) }
                }
            }
            .padding()
            
            // Restart button
            Button("Restart Level") {
                setupGame()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .padding(.bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { setupGame() }
        .alert("🎉 You Win!", isPresented: $gameCompleted) {
            Button("Play Again") { setupGame() }
        } message: {
            Text("Final Score: \(score)\nTotal Moves: \(moves)")
        }
    }
    
    // MARK: - Game Logic
    func setupGame() {
        let totalTiles = level.gridSize * level.gridSize
        let pairCount = totalTiles / 2
        
        var newTiles: [Tile] = []
        for i in 0..<pairCount {
            let color = allColors[i % allColors.count]
            newTiles.append(Tile(color: color))
            newTiles.append(Tile(color: color))
        }
        
        // Add blocked tile if total is odd
        if totalTiles % 2 != 0 {
            newTiles.append(Tile(color: .clear, isBlocked: true))
        }
        
        newTiles.shuffle()
        tiles = newTiles
        selectedTiles.removeAll()
        score = 0
        moves = 0
        gameCompleted = false
    }
    
    func tileTapped(_ index: Int) {
        guard !isChecking,
              !tiles[index].isMatched,
              !tiles[index].isRevealed else { return }
        
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
        let first = selectedTiles[0]
        let second = selectedTiles[1]
        
        if tiles[first].color == tiles[second].color {
            tiles[first].isMatched = true
            tiles[second].isMatched = true
            score += 10
            finishTurn()
        } else {
            score -= 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                tiles[first].isRevealed = false
                tiles[second].isRevealed = false
                finishTurn()
            }
        }
    }
    
    func finishTurn() {
        selectedTiles.removeAll()
        isChecking = false
        
        if tiles.allSatisfy({ $0.isMatched || $0.isBlocked }) {
            gameCompleted = true
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
                      ? (tile.isBlocked ? Color.black.opacity(0.25) : tile.color)
                      : Color.gray.opacity(0.6))
                .shadow(color: .black.opacity(0.3), radius: 5, x: 3, y: 3)
            
            if tile.isBlocked && tile.isRevealed {
                Image(systemName: "nosign")
                    .font(.largeTitle)
                    .foregroundColor(.red)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.6), lineWidth: 1)
        )
        .animation(.easeInOut, value: tile.isRevealed)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
