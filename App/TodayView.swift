import SwiftUI

/// Starts today's routine and the lock screen activity. Used by the Start button and the widgets.
@MainActor
func beginWorkout(store: Store, rest: RestController) {
    store.startWorkout()
    rest.requestNotificationPermission()
    guard let s = store.data.session else { return }
    let first = s.items.compactMap { $0.exerciseID }.first.flatMap { Library.byID[$0]?.name } ?? "Workout"
    rest.beginWorkout(routine: s.routine.title, startedAt: s.start, first: first)
}

struct TodayView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var rest: RestController
    @State private var showEquipment = false
    @State private var showPlans = false
    @State private var trainAnyway = false

    private var resting: Bool { store.isRestDay && !trainAnyway }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if resting {
                    restCard
                    weekCard
                    weekSoFar
                } else {
                    heroCard
                    weekCard
                    routinePicker
                    lineupCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .tabBarClearance()
        .background { SkyBackground() }
        .sheet(isPresented: $showEquipment) {
            EquipmentSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPlans) {
            ProgramsView()
        }
    }

    // MARK: Header

    @ViewBuilder
    private var header: some View {
        switch Theme.skin.header {
        case .standard:
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(Theme.font(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.headSub)
                    Text(Theme.words.train)
                        .font(Theme.display(34))
                        .foregroundStyle(Theme.head)
                }
                Spacer()
                headerButtons
            }
        case .masthead:
            VStack(spacing: 8) {
                VStack(spacing: 6) {
                    Text("The Ironlog")
                        .font(Skin.blackletter.font(42))
                        .foregroundStyle(Theme.head)
                    HStack {
                        Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
                        Spacer()
                        Text("WEEK \(weekNumber)")
                        Spacer()
                        Text("\(store.entriesThisWeek().count) OF \(store.data.plan.days) DONE")
                    }
                    .font(Theme.label(10, .bold))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.head)
                }
                .padding(.vertical, 8)
                .overlay(alignment: .top) { Rectangle().fill(Theme.ink).frame(height: 1) }
                .overlay(alignment: .bottom) {
                    VStack(spacing: 2) {
                        Rectangle().fill(Theme.ink).frame(height: 1)
                        Rectangle().fill(Theme.ink).frame(height: 1)
                    }
                }
                HStack {
                    Spacer()
                    headerButtons
                }
            }
        case .prompt:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("ironlog · ~/train")
                    Spacer()
                    Text(Date().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).lowercased())
                }
                .font(Theme.font(size: 12))
                .foregroundStyle(Theme.headSub)
                HStack(spacing: 14) {
                    Button { showPlans = true } label: {
                        Text("[plan: \(store.data.plan.name.lowercased())]")
                    }
                    Button { showEquipment = true } label: {
                        Text("[gear]")
                    }
                    Spacer()
                }
                .font(Theme.font(size: 13, weight: .bold))
                .foregroundStyle(Theme.accent)
                .buttonStyle(.plain)
            }
        case .hud:
            let filled = store.entriesThisWeek().count
            let volume = store.entriesThisWeek().reduce(0) { $0 + $1.volume }
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vice City")
                            .font(Skin.script.font(32))
                            .foregroundStyle(Color(red: 1, green: 0.44, blue: 0.68))
                            .shadow(color: Color(red: 1, green: 0.31, blue: 0.6).opacity(0.8), radius: 8)
                            .textCase(nil)
                        (Text(Date().formatted(.dateTime.weekday(.abbreviated))) + Text(" · ") + Text(Date(), style: .time))
                            .font(Theme.font(size: 12, weight: .semibold))
                            .tracking(0.8)
                            .textCase(.uppercase)
                            .foregroundStyle(Theme.headSub)
                            .shadow(color: .black, radius: 2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(volume).formatted()) LB")
                            .font(Theme.display(28, .bold))
                            .foregroundStyle(Color(red: 0.49, green: 0.88, blue: 0.54))
                            .outlined(Color(red: 0.04, green: 0.02, blue: 0.07), width: 1.4)
                            .accessibilityLabel("\(Int(volume)) pounds moved this week")
                        WantedStars(filled: filled, total: store.data.plan.days)
                    }
                }
                HStack {
                    Spacer()
                    headerButtons
                }
            }
        case .menubar:
            HStack(spacing: 16) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 15, weight: .black))
                Text("Train").font(Theme.font(size: 15, weight: .bold))
                Button(store.data.plan.name) { showPlans = true }
                    .lineLimit(1)
                Button("Gear") { showEquipment = true }
                Spacer(minLength: 0)
                Text(Date(), style: .time)
            }
            .font(Theme.font(size: 15, weight: .medium))
            .foregroundStyle(.black)
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .frame(height: 32)
            .background(Color.white)
            .overlay(alignment: .bottom) { Rectangle().fill(.black).frame(height: 2) }
            .padding(.horizontal, -20)
            .padding(.top, -8)
            .padding(.bottom, 6)
        case .bug:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 2) {
                    HStack(spacing: 6) {
                        Circle().fill(.white).frame(width: 7, height: 7)
                        Text("LIVE")
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 30)
                    .background(Theme.accent, in: Slant(amount: 0.3))
                    .foregroundStyle(.white)
                    Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .padding(.horizontal, 14)
                        .frame(height: 30)
                        .background(Color.white, in: Slant(amount: 0.3))
                        .foregroundStyle(Color(red: 0.04, green: 0.07, blue: 0.16))
                    Spacer()
                    Text("WK \(weekNumber)").foregroundStyle(Theme.sub).padding(.trailing, 8)
                    Text("\(store.entriesThisWeek().count)/\(store.data.plan.days)")
                        .foregroundStyle(Theme.accentText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .overlay(Rectangle().strokeBorder(Theme.accentText, lineWidth: 1.5))
                }
                .font(Theme.label(15, .heavy))
                HStack {
                    Spacer()
                    headerButtons
                }
            }
        }
    }

    private var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: Date())
    }

    private var headerButtons: some View {
        HStack(spacing: 8) {
            Button {
                showPlans = true
            } label: {
                HStack(spacing: 5) {
                    Text(store.data.plan.name)
                        .font(Theme.font(size: 13, weight: .bold))
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.sub)
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .frame(height: 36)
            }
            .themedChipButton()
            .accessibilityLabel("Plan: \(store.data.plan.name). Change plan")
            Button {
                showEquipment = true
            } label: {
                Image(systemName: "dumbbell")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: Theme.skin.isGlacier ? 44 : 36, height: Theme.skin.isGlacier ? 44 : 36)
            }
            .themedChipButton(circle: true)
            .accessibilityLabel("What's open")
        }
    }

    // MARK: Up next

    private var routine: RoutineID { store.todayRoutine }
    private var exerciseCount: Int { store.plan(routine).compactMap { $0 }.count }
    private var takenCount: Int { Equipment.allCases.filter { !store.data.open.contains($0) }.count }
    private var kicker: String { routine == store.nextRoutine ? Theme.words.upNext : Theme.words.picked }

    @ViewBuilder
    private var heroCard: some View {
        switch Theme.skin.hero {
        case .standard: standardHero
        case .mainEvent: mainEventHero
        case .lowerThird: lowerThirdHero
        case .mission: missionHero
        }
    }

    private var startButton: some View {
        VStack(spacing: 10) {
            intensityBar
            Button {
                start()
            } label: {
                if Theme.skin.isGlacier {
                    Label(Theme.words.start, systemImage: "play.fill")
                } else {
                    Text(Theme.words.start)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    /// Pick how much to do today. Sticks to whatever you used last.
    private var intensityBar: some View {
        let current = store.data.plan.intensity
        return HStack(spacing: 4) {
            ForEach(Intensity.allCases) { level in
                let on = level == current
                let minutes = store.estimatedMinutes(routine, plan: store.data.plan.with(level))
                Button {
                    withAnimation(.snappy) { store.setIntensity(level) }
                } label: {
                    VStack(spacing: 1) {
                        Text(level.name)
                            .font(Theme.font(size: 14, weight: .bold))
                        Text("\(level.exercises) ex · \(minutes)m")
                            .font(Theme.font(size: 11, weight: .semibold))
                            .opacity(on ? 0.9 : 0.75)
                            .textCase(nil)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(on ? Theme.accent : Theme.chip, in: RoundedRectangle(cornerRadius: Theme.radius(12), style: .continuous))
                    .foregroundStyle(on ? Theme.accentInk : Theme.ink)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(level.name): \(level.exercises) exercises, about \(minutes) minutes")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: current)
    }

    private var standardHero: some View {
        let lastText: String = {
            if let d = store.lastDone(routine) {
                return "Last done " + d.formatted(.dateTime.weekday(.abbreviated))
            }
            return "Not done yet"
        }()
        let caps = Theme.skin.titleCaps
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Pill(text: kicker)
                Spacer()
                Text(lastText)
                    .font(Theme.font(size: 13, weight: .medium))
                    .foregroundStyle(Theme.sub)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(caps ? routine.title.uppercased() : routine.title)
                    .font(Theme.display(Theme.skin.heroSize))
                    .lineLimit(caps ? 2 : 1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(Theme.skin.card == .aero ? Color(red: 0.12, green: 0.25, blue: 0.54) : Theme.ink)
                Text(routine.subtitle)
                    .font(Theme.font(size: 15))
                    .foregroundStyle(Theme.sub)
            }
            metaRow
            startButton
        }
        .glacierCard(radius: 28, padding: 20, title: Theme.skin.card == .aero ? "Up next" : Theme.words.upNext.capitalized)
    }

    private var metaRow: some View {
        HStack(spacing: 16) {
            meta("list.bullet", exerciseCount.counted("exercise"))
            meta("clock", "About \(store.estimatedMinutes(routine)) min")
            Button {
                showEquipment = true
            } label: {
                meta(takenCount == 0 ? "checkmark" : "exclamationmark.circle",
                     takenCount == 0 ? "All gear open" : "\(takenCount) taken")
            }
            .buttonStyle(.plain)
        }
    }

    /// 80s fight poster: banner, chrome title, "VS." the muscles.
    private var mainEventHero: some View {
        let muscles = routine.subtitle.uppercased().replacingOccurrences(of: ", ", with: " · ")
        return VStack(spacing: 10) {
            Text(kicker)
                .font(Theme.display(16, .regular))
                .tracking(2.4)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 5)
                .background(Theme.accent, in: Slant(amount: 0.35))
                .shadow(color: Color(red: 0.43, green: 0.04, blue: 0.09), radius: 0, x: 4, y: 4)
            ChromeTitle(text: routine.title, size: Theme.skin.heroSize)
                .padding(.vertical, 2)
            (Text("VS. ").foregroundColor(Theme.accentText) + Text(muscles))
                .font(Theme.display(21, .regular))
                .tracking(0.8)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("\(exerciseCount.counted("match").uppercased()) · \(store.estimatedMinutes(routine)) MIN · \(takenCount == 0 ? "ALL GEAR CLEARED" : "\(takenCount) TAKEN")")
                .font(Theme.font(size: 13, weight: .medium))
                .tracking(1.6)
                .foregroundStyle(Theme.sub)
                .multilineTextAlignment(.center)
            startButton
                .padding(.top, 8)
            RingRopes()
                .padding(.horizontal, -20)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
    }

    /// TV lower third: tag, white panel, stat chips.
    private var lowerThirdHero: some View {
        let navy = Color(red: 0.04, green: 0.07, blue: 0.16)
        return VStack(alignment: .leading, spacing: 0) {
            Text(kicker)
                .font(Theme.label(14, .heavy))
                .tracking(2)
                .foregroundStyle(navy)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(Theme.accentText, in: Slant(amount: 0.3))
                .padding(.leading, 6)
            VStack(alignment: .leading, spacing: 0) {
                Text(routine.title.uppercased())
                    .font(Theme.display(Theme.skin.heroSize, .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(routine.subtitle.uppercased().replacingOccurrences(of: ", ", with: " · "))
                    .font(Theme.font(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.23, green: 0.27, blue: 0.44))
            }
            .foregroundStyle(navy)
            .padding(.leading, 18)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [.white, Color(red: 0.9, green: 0.92, blue: 0.96)], startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .leading) { Rectangle().fill(Theme.accent).frame(width: 8) }
            .shadow(color: .black.opacity(0.45), radius: 12, y: 8)
            HStack(spacing: 3) {
                statChip("\(exerciseCount)", "EXERCISES")
                statChip("\(store.estimatedMinutes(routine))", "MINUTES")
                Button { showEquipment = true } label: {
                    statChip(takenCount == 0 ? "✓" : "\(takenCount)", takenCount == 0 ? "GEAR" : "TAKEN", color: takenCount == 0 ? Theme.good : Theme.accentText)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 3)
            startButton
                .padding(.top, 14)
        }
    }

    private func statChip(_ value: String, _ label: String, color: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(Theme.num(24, .heavy)).foregroundStyle(color)
            Text(label).font(Theme.label(12, .semibold)).tracking(1).foregroundStyle(Theme.sub)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.11, green: 0.16, blue: 0.36))
    }

    /// GTA-style mission: painted panel, objective line, start.
    private var missionHero: some View {
        let ink = Color(red: 0.04, green: 0.02, blue: 0.07)
        let last = store.lastDone(routine).map { "LAST PLAYED " + $0.formatted(.dateTime.weekday(.abbreviated)).uppercased() } ?? "NEW MISSION"
        return VStack(spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                Image("ViceHero")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 206)
                    .frame(maxWidth: .infinity)
                    .clipped()
                LinearGradient(colors: [ink.opacity(0), ink.opacity(0.75)], startPoint: UnitPoint(x: 0.5, y: 0.55), endPoint: .bottom)
                VStack(alignment: .leading, spacing: 0) {
                    Text(kicker)
                        .font(Theme.display(18, .bold))
                        .tracking(1.4)
                        .foregroundStyle(Theme.accentText)
                        .outlined(ink, width: 1.2)
                    Text(routine.title.uppercased())
                        .font(Theme.display(Theme.skin.heroSize, .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(.white)
                        .outlined(ink, width: 2)
                }
                .padding(14)
            }
            .overlay(alignment: .topTrailing) {
                Text(last)
                    .font(Theme.font(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 2)
                    .padding(10)
            }
            .overlay(Rectangle().strokeBorder(ink, lineWidth: 3))
            .shadow(color: .black.opacity(0.5), radius: 15, y: 10)
            ViceText.objective(routine.subtitle)
                .font(Theme.font(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black, radius: 2)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 6)
            startButton
            HStack {
                Spacer()
                metaRow
                Spacer()
            }
        }
    }

    // MARK: Rest day

    private var restCard: some View {
        let next = store.nextRoutine
        let day = store.nextPlannedDate().map { $0.formatted(.dateTime.weekday(.wide)) } ?? "next time"
        return VStack(alignment: .leading, spacing: 14) {
            Pill(text: "REST DAY", fill: Theme.chip, ink: Theme.sub)
            VStack(alignment: .leading, spacing: 4) {
                Text("Recover today")
                    .font(Theme.font(size: 32, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                (Text("Next up is ") + Text("\(next.title) on \(day)").bold().foregroundStyle(Theme.ink) + Text("."))
                    .font(Theme.font(size: 15))
                    .foregroundStyle(Theme.sub)
            }
            HStack(spacing: 12) {
                Text(next.glyph)
                    .font(Theme.font(size: 12, weight: .heavy))
                    .foregroundStyle(Theme.sub)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Theme.sub.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [4, 3])))
                VStack(alignment: .leading, spacing: 2) {
                    Text(next.title).font(Theme.font(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                    Text(store.plan(next).compactMap { $0 }.count.counted("exercise") + " · about \(store.estimatedMinutes(next)) min")
                        .font(Theme.font(size: 12))
                        .foregroundStyle(Theme.sub)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Theme.field, in: RoundedRectangle(cornerRadius: Theme.radius(18), style: .continuous))
            Button("Train anyway") {
                withAnimation(.snappy) { trainAnyway = true }
            }
            .buttonStyle(OutlineButtonStyle())
        }
        .glacierCard(radius: 28, padding: 20)
    }

    private var weekSoFar: some View {
        let planned = store.weeklySets(for: store.data.plan)
        let done = store.setsThisWeek()
        let muscles = Muscle.allCases.filter { (planned[$0] ?? 0) > 0 }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("This week so far")
                Spacer()
                Text("sets done / planned")
                    .font(Theme.font(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.sub)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                ForEach(muscles) { m in
                    let d = done[m] ?? 0
                    let p = max(1, planned[m] ?? 1)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(m.name)
                            .font(Theme.font(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.sub)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        (Text("\(d)").font(Theme.num(15)) + Text(" / \(p)").font(Theme.font(size: 12, weight: .semibold)).foregroundStyle(Theme.sub))
                            .foregroundStyle(Theme.ink)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.faint)
                                Capsule().fill(Theme.accent).frame(width: geo.size.width * min(1, CGFloat(d) / CGFloat(p)))
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(10)
                    .background(Theme.field, in: RoundedRectangle(cornerRadius: Theme.radius(14), style: .continuous))
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .glacierCard(padding: 16)
    }

    private func meta(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(Theme.font(size: 12, weight: .bold))
            Text(text)
        }
        .font(Theme.font(size: 13, weight: .semibold))
        .foregroundStyle(Theme.sub)
        .lineLimit(1)
    }

    private func start() {
        beginWorkout(store: store, rest: rest)
    }

    // MARK: Week

    @ViewBuilder
    private var weekCard: some View {
        if Theme.skin.dot == .score {
            lineScore
        } else {
            weekStrip
        }
    }

    private var weekStrip: some View {
        let done = store.entriesThisWeek().count
        let dot = Theme.skin.dot
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(Theme.words.thisWeek)
                Spacer()
                Text(Theme.skin.id == "mainevent" ? "\(done)–0 OF \(store.data.plan.days)" : "\(done) of \(store.data.plan.days) done")
                    .contentTransition(.numericText(value: Double(done)))
                    .font(Theme.font(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.skin.id == "mainevent" ? Theme.accentText : Theme.sub)
            }
            if Theme.skin.id == "8bit" {
                // XP bar: one block per planned workout.
                HStack(spacing: 4) {
                    ForEach(0..<max(1, store.data.plan.days), id: \.self) { i in
                        Rectangle().fill(i < done ? Theme.accent : Theme.faint).frame(height: 10)
                    }
                }
                .accessibilityHidden(true)
            }
            HStack(spacing: dot == .square || dot == .skew ? 5 : 0) {
                ForEach(store.weekDays()) { day in
                    VStack(spacing: 6) {
                        Text(dot == .skew ? dayName(day.id) : day.letter)
                            .font(Theme.font(size: 12, weight: day.planned || day.done ? .semibold : .medium))
                            .foregroundStyle(day.isToday && !Theme.skin.isGlacier ? Theme.accentText : (day.planned || day.done ? Theme.sub : Theme.sub.opacity(0.6)))
                        dayDot(day)
                            .frame(height: dot == .skew ? 38 : 32)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .glacierCard(padding: 16)
    }

    private func dayName(_ i: Int) -> String {
        ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"][min(max(i, 0), 6)]
    }

    @ViewBuilder
    private func dayDot(_ day: Store.DayDot) -> some View {
        switch Theme.skin.dot {
        case .circle, .score:
            circleDot(day, gloss: false)
        case .gloss:
            circleDot(day, gloss: true)
        case .square:
            squareDot(day)
        case .checkbox:
            checkboxDot(day)
        case .skew:
            skewDot(day)
        case .blip:
            blipDot(day)
        case .text:
            textDot(day)
        }
    }

    @ViewBuilder
    private func circleDot(_ day: Store.DayDot, gloss: Bool) -> some View {
        if let routine = day.routine {
            Circle()
                .fill(gloss ? AnyShapeStyle(RadialGradient(colors: [Color(red: 0.9, green: 1, blue: 0.85), Theme.done, Theme.done.opacity(0.8)], center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 20)) : AnyShapeStyle(Theme.accent))
                .frame(width: 32, height: 32)
                .overlay {
                    if gloss {
                        Image(systemName: "checkmark").font(.system(size: 13, weight: .heavy)).foregroundStyle(.white).shadow(radius: 1)
                    } else {
                        RoutineBadge(routine: routine).foregroundStyle(Theme.accentInk)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel(routine.title)
        } else if !day.planned {
            // Off day in a plan with set days.
            Circle()
                .strokeBorder(day.isToday ? Theme.accent : Color.clear, lineWidth: 2)
                .background(Circle().fill(day.isToday ? Color.clear : Theme.faint))
                .frame(width: day.isToday ? 12 : 7, height: day.isToday ? 12 : 7)
                .accessibilityLabel(day.isToday ? "Today, rest day" : "Rest day")
        } else if day.isToday {
            Circle()
                .strokeBorder(Theme.accent, lineWidth: 2)
                .background(Circle().fill(gloss ? Color.white : Color.clear))
                .shadow(color: gloss ? Theme.accent.opacity(0.7) : .clear, radius: 5)
                .frame(width: 32, height: 32)
        } else if day.isFuture && store.data.plan.isFixed {
            Circle()
                .strokeBorder(Theme.sub.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .frame(width: 32, height: 32)
                .accessibilityLabel("Planned")
        } else {
            Circle()
                .fill(Theme.faint)
                .frame(width: 32, height: 32)
        }
    }

    @ViewBuilder
    private func squareDot(_ day: Store.DayDot) -> some View {
        if let routine = day.routine {
            Rectangle()
                .fill(Theme.done)
                .overlay(RoutineBadge(routine: routine).foregroundStyle(Theme.doneInk))
                .overlay(alignment: .bottom) {
                    if Theme.skin.id == "8bit" { Rectangle().fill(.black.opacity(0.25)).frame(height: 3) }
                }
                .accessibilityElement()
                .accessibilityLabel(routine.title)
        } else if day.isToday {
            Rectangle().strokeBorder(Theme.accent, lineWidth: 3)
                .accessibilityLabel(day.planned ? "Today" : "Today, rest day")
        } else if !day.planned {
            Rectangle().fill(Theme.faint.opacity(0.5)).frame(height: 8)
                .accessibilityLabel("Rest day")
        } else {
            Rectangle().fill(Theme.faint)
        }
    }

    @ViewBuilder
    private func checkboxDot(_ day: Store.DayDot) -> some View {
        ZStack {
            Rectangle().fill(.white)
            Rectangle().strokeBorder(.black, lineWidth: 2)
            if day.done {
                Path { p in
                    p.move(to: CGPoint(x: 4, y: 4)); p.addLine(to: CGPoint(x: 16, y: 16))
                    p.move(to: CGPoint(x: 16, y: 4)); p.addLine(to: CGPoint(x: 4, y: 16))
                }
                .stroke(.black, lineWidth: 2)
            }
        }
        .frame(width: 20, height: 20)
        .padding(3)
        .overlay {
            if day.isToday {
                Rectangle().strokeBorder(.black, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
            }
        }
        .opacity(day.planned || day.done ? 1 : 0.35)
        .accessibilityElement()
        .accessibilityLabel(day.routine?.title ?? (day.isToday ? "Today" : (day.planned ? "Planned" : "Rest day")))
    }

    @ViewBuilder
    private func skewDot(_ day: Store.DayDot) -> some View {
        Group {
            if day.done {
                Rectangle().fill(Theme.done)
                    .overlay(Text("W").font(Theme.display(18, .regular)).foregroundStyle(Theme.doneInk))
            } else if day.isToday && day.planned {
                Rectangle().fill(Theme.accent)
                    .overlay(Text("LIVE").font(Theme.display(11, .regular)).tracking(0.6).foregroundStyle(.white))
                    .shadow(color: Theme.accent.opacity(0.7), radius: 7)
            } else if day.planned && day.isFuture && store.data.plan.isFixed {
                Rectangle().strokeBorder(Theme.cardBorder, lineWidth: 2)
                    .overlay(Text("TBA").font(Theme.font(size: 11, weight: .bold)).foregroundStyle(Theme.sub))
            } else {
                Rectangle().strokeBorder(Theme.cardBorder.opacity(day.planned ? 1 : 0.4), lineWidth: 2)
            }
        }
        .lean(0.14, height: 38)
        .accessibilityElement()
        .accessibilityLabel(day.done ? "Won: \(day.routine?.title ?? "")" : (day.isToday ? "Tonight" : "Open"))
    }

    @ViewBuilder
    private func blipDot(_ day: Store.DayDot) -> some View {
        let ink = Color(red: 0.04, green: 0.02, blue: 0.07)
        if day.done {
            Circle().fill(Theme.done)
                .overlay(Circle().strokeBorder(ink, lineWidth: 2))
                .overlay(Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy)).foregroundStyle(.white))
                .frame(width: 26, height: 26)
                .accessibilityLabel(day.routine?.title ?? "Done")
        } else if day.isToday {
            Circle().fill(Theme.accentText)
                .overlay(Circle().strokeBorder(ink, lineWidth: 2))
                .frame(width: 26, height: 26)
                .shadow(color: Theme.accentText.opacity(0.9), radius: 8)
                .accessibilityLabel("Today")
        } else {
            Circle().strokeBorder(.white.opacity(day.planned ? 0.25 : 0.1), lineWidth: 2)
                .frame(width: 26, height: 26)
        }
    }

    @ViewBuilder
    private func textDot(_ day: Store.DayDot) -> some View {
        let terminal = Theme.skin.id == "terminal"
        if let routine = day.routine {
            HStack(spacing: 1) {
                if terminal { Text("✓") }
                RoutineBadge(routine: routine)
            }
            .font(Theme.font(size: 13, weight: .heavy))
            .foregroundStyle(Theme.accent)
            .accessibilityElement()
            .accessibilityLabel(routine.title)
        } else if day.isToday {
            Text(terminal ? "▸ now" : "today")
                .font(Theme.font(size: 13, weight: .heavy))
                .foregroundStyle(Theme.accentText)
        } else {
            Text(terminal ? "--" : "·")
                .font(Theme.font(size: 14))
                .foregroundStyle(Theme.faint)
        }
    }

    /// Broadcast line score: one row of days and a total.
    private var lineScore: some View {
        let done = store.entriesThisWeek().count
        let days = store.weekDays()
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(Theme.words.thisWeek)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                ForEach(days) { d in
                    Text(d.letter)
                        .foregroundStyle(d.isToday ? Theme.accentText : Theme.sub)
                        .frame(width: 26)
                }
                Text("TOT")
                    .foregroundStyle(.white)
                    .frame(width: 52)
                    .frame(maxHeight: .infinity)
                    .background(Theme.accent)
            }
            .font(Theme.label(13, .bold))
            .frame(height: 28)
            .background(Theme.chip)
            HStack(spacing: 0) {
                Text("SESSIONS")
                    .font(Theme.font(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.sub)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                ForEach(days) { d in
                    Group {
                        if d.done {
                            Text("1").foregroundStyle(.white)
                        } else if d.isToday {
                            Text("▶").foregroundStyle(Theme.accentText)
                        } else {
                            Text("–").foregroundStyle(Theme.faint)
                        }
                    }
                    .font(Theme.num(16, .bold))
                    .frame(width: 26)
                }
                (Text("\(done)").font(Theme.num(20, .heavy)) + Text("/\(store.data.plan.days)").font(Theme.font(size: 13, weight: .semibold)).foregroundColor(Theme.sub))
                    .foregroundStyle(.white)
                    .frame(width: 52)
                    .frame(maxHeight: .infinity)
                    .background(Theme.accent.opacity(0.18))
            }
            .frame(height: 38)
            .background(Color.black.opacity(0.35))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(done) of \(store.data.plan.days) workouts this week")
    }

    // MARK: Routine picker

    private var routinePicker: some View {
        let selected = store.todayRoutine
        var seen = Set<RoutineID>()
        let options = store.data.plan.rotation.filter { seen.insert($0).inserted }
        return Group {
            if options.count > 4 {
                ScrollView(.horizontal, showsIndicators: false) {
                    pickerRow(options, selected: selected, fixedWidth: true)
                }
            } else {
                pickerRow(options, selected: selected, fixedWidth: false)
            }
        }
        .padding(5)
        .background(Theme.skin.card == .aero ? Color.white.opacity(0.85) : Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius(18), style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius(18), style: .continuous).stroke(Theme.skin.isGlacier ? Theme.cardBorder : Theme.fieldBorder, lineWidth: 1))
    }

    private func pickerRow(_ options: [RoutineID], selected: RoutineID, fixedWidth: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(options) { r in
                Button {
                    withAnimation(.snappy) { store.data.selectedRoutine = r }
                } label: {
                    Text(r.shortTitle)
                        .font(Theme.font(size: 13, weight: .bold))
                        .padding(.horizontal, fixedWidth ? 14 : 0)
                        .frame(maxWidth: fixedWidth ? nil : .infinity, minHeight: 40)
                        .background(r == selected ? Theme.accent : Color.clear, in: RoundedRectangle(cornerRadius: Theme.radius(14), style: .continuous))
                        .foregroundStyle(r == selected ? Theme.accentInk : Theme.sub)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(r == selected ? .isSelected : [])
            }
        }
    }

    // MARK: Lineup

    private var lineupCard: some View {
        let routine = store.todayRoutine
        let picks = store.plan(routine)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionTitle(Theme.words.lineup)
                Spacer()
                Button("What's open") { showEquipment = true }
                    .font(Theme.font(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accentText)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 6)
            ForEach(Array(routine.active(store.data.plan.intensity).enumerated()), id: \.element) { n, i in
                LineupRow(index: n + 1, slot: routine.slots[i], exercise: picks[i], routine: routine)
            }
        }
        .glacierCard(padding: 0)
    }
}

private struct LineupRow: View {
    @EnvironmentObject private var store: Store
    let index: Int
    let slot: Slot
    let exercise: Exercise?
    let routine: RoutineID
    @State private var showClip = false

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index)")
                .font(Theme.font(size: 13, weight: .bold))
                .frame(width: 28, height: 28)
                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: Theme.radius(9), style: .continuous))
                .foregroundStyle(Theme.accentText)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(exercise?.name ?? "Nothing open for \(slot.label.lowercased())")
                        .font(Theme.font(size: 16, weight: .semibold))
                        .foregroundStyle(exercise == nil ? Theme.sub : Theme.ink)
                    if let ex = exercise, store.isFocus(ex.id) {
                        Text("FOCUS")
                            .font(Theme.font(size: 9, weight: .heavy))
                            .tracking(0.6)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.radius(5), style: .continuous))
                            .foregroundStyle(Theme.accentInk)
                    }
                }
                if let ex = exercise {
                    Text(store.prescription(ex.id, routine: routine).short(for: ex) + " rest")
                        .font(Theme.font(size: 13))
                        .foregroundStyle(Theme.sub)
                }
            }
            Spacer(minLength: 0)
            if let ex = exercise {
                Button {
                    showClip = true
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(Theme.font(size: 28))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Theme.accentInk, Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Form video for \(ex.name)")
                .sheet(isPresented: $showClip) {
                    ClipPlayerSheet(exercise: ex)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.faint).frame(height: 1)
        }
    }
}

/// Equipment toggles as chips (used in Settings).
struct EquipmentChips: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
            ForEach(Equipment.allCases) { eq in
                let isOpen = store.data.open.contains(eq)
                Button {
                    withAnimation(.snappy) { store.toggleEquipment(eq) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isOpen ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(isOpen ? Theme.accent : Theme.sub)
                        Text(eq.name)
                            .font(Theme.font(size: 14, weight: .semibold))
                            .strikethrough(!isOpen)
                            .foregroundStyle(isOpen ? Theme.ink : Theme.sub)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(isOpen ? Theme.accentSoft : Theme.chip, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Arrow plus letter (↑A, ↕B) or a short tag (Pu, Pl, Lg, Ar) for a routine.
struct RoutineBadge: View {
    let routine: RoutineID

    var body: some View {
        HStack(spacing: 0) {
            if let arrow = routine.arrowSymbol {
                Image(systemName: arrow)
                    .font(Theme.font(size: 10, weight: .black))
            }
            Text(routine.badge)
                .font(Theme.font(size: routine.arrowSymbol == nil ? 11 : 12, weight: .heavy))
        }
    }
}
