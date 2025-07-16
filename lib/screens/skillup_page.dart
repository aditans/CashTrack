import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SkillupPage(),
    );
  }
}

class SkillupPage extends StatefulWidget {
  const SkillupPage({super.key});

  @override
  State<SkillupPage> createState() => _SkillupPageState();
}

class _SkillupPageState extends State<SkillupPage> {

  void _showFlipDialog(
      BuildContext context,
      Color color,
      String text,
      String question,
      String answer,
      ) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.6,
          child: FlipCard(
            front: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/chippyquestion.png',
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            back: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Opacity(
                    opacity: 0.4, // value between 0.0 (transparent) and 1.0 (opaque)
                    child: Image.asset(
                      'assets/bg.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Semi-transparent overlay (optional for readability)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                  ),

                  // Content (image + text)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image above the answer text
                        Image.asset(
                          'assets/chippyhappy.png', // Your image above the answer
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          answer,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.transparent,
        backgroundColor: const Color(0xFF00CCE7),
        leadingWidth: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 2.0),
          child: Image.asset(
            'assets/logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        title: Transform.translate(
          offset: const Offset(-25, -5),
          child: const Text(
            'Skill Up',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 30,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Transform.translate(
              offset: const Offset(0, -5),
              child: const Icon(
                Icons.account_circle,
                size: 50,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Tip of the Day
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    ClipOval(
                      child: Image.asset(
                        'assets/chippy.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Tip of the Day',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Colors.yellow.shade700,
                        size: 32,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          'Always track your expenses daily to avoid overspending.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Section 2: Car Affordability
              _SectionHeader(
                icon: Icons.directions_car,
                label: 'Car Affordability',
                colorx: Colors.green,
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: List.generate(4, (index) {
                  final questions = [
                    ' Rule for Buying a Car?',
                    'Should I buy or lease?',
                    'What is car depreciation?',
                    'Best time to buy a car?'
                  ];
                  final answers = [
                    'The 20/4/10 rule is a smart budgeting guide for buying a car. It suggests paying 20% upfront, keeping your car loan EMI under 10% of your monthly income, and ensuring total car expenses (including fuel and insurance) stay below 40% of your income. This helps you avoid financial stress while owning a car.',
                    'Buying is long-term ownership, leasing is short-term use.',
                    'Depreciation is the loss in value of the car over time.',
                    'Festive seasons and year-end sales are ideal.'
                  ];
                  return GestureDetector(
                    onTap: () => _showFlipDialog(
                      context,
                      Colors.blue,
                      'Feature #${index + 1}',
                      questions[index],
                      answers[index],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/bluecard.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Section 3: Saving Rules
              _SectionHeader(
                icon: Icons.savings,
                label: 'Saving Rules',
                colorx: Colors.green,
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: List.generate(4, (index) {
                  final questions = [
                    'What is the 50/30/20 rule?',
                    'Why save emergency funds?',
                    'What is compound interest?',
                    'How to track expenses?'
                  ];
                  final answers = [
                    '50% needs, 30% wants, 20% savings.',
                    'For unexpected expenses like medical bills.',
                    'Interest on interest earned over time.',
                    'Use budgeting apps or notebooks daily.'
                  ];
                  return GestureDetector(
                    onTap: () => _showFlipDialog(
                      context,
                      Colors.green,
                      'Rule #${index + 1}',
                      questions[index],
                      answers[index],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/greencard.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.school), label: 'SkillUp'),
          BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz), label: 'Transactions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group), label: 'Splits'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color colorx;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.colorx,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: colorx, size: 32),
        const SizedBox(width: 8),
        Text(
          overflow: TextOverflow.ellipsis,
          label,
          style: TextStyle(
            fontSize: 24,
            color: colorx,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class SkillUp extends StatelessWidget {
  const SkillUp({super.key});
  void _showFlipDialog(
      BuildContext context,
      Color color,
      String text,
      String question,
      String answer, Color white,
      ) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.6,
          child: FlipCard(
            front: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/chippyquestion.png',
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            back: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Opacity(
                    opacity: 0.4, // value between 0.0 (transparent) and 1.0 (opaque)
                    child: Image.asset(
                      'assets/bg.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Semi-transparent overlay (optional for readability)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                  ),

                  // Content (image + text)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image above the answer text
                        Image.asset(
                          'assets/chippyhappy.png', // Your image above the answer
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          answer,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Tip of the Day
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  ClipOval(
                    child: Image.asset(
                      'assets/chippy.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Tip of the Day',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.yellow.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Always track your expenses daily to avoid overspending.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Section 2: Car Affordability
            _SectionHeader(
              icon: Icons.directions_car,
              label: 'Car Affordability',
              colorx: Colors.blue,
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: List.generate(4, (index) {
                final questions = [
                  'What is 20 / 4 / 10 Rule for Buying a Car?',
                  'Should I buy or lease?',
                  'What is car depreciation?',
                  'Best time to buy a car?'
                ];
                final answers = [
                  'The 20/4/10 rule is a smart budgeting guide for buying a car. It suggests paying 20% upfront, keeping your car loan EMI under 10% of your monthly income, and ensuring total car expenses (including fuel and insurance) stay below 40% of your income. This helps you avoid financial stress while owning a car.',
                  'Buying is long-term ownership, leasing is short-term use.',
                  'Depreciation is the loss in value of the car over time.',
                  'Festive seasons and year-end sales are ideal.'
                ];
                return GestureDetector(
                  onTap: () => _showFlipDialog(
                    context,
                    Colors.blue,
                    'Feature #${index + 1}',
                    questions[index],
                    answers[index],
                    Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/bluecard.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Section 3: Saving Rules
            _SectionHeader(
              icon: Icons.savings,
              label: 'Saving Rules',
              colorx: Colors.green,
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: List.generate(4, (index) {
                final questions = [
                  'What is the 50/30/20 rule?',
                  'Why save emergency funds?',
                  'What is compound interest?',
                  'How to track expenses?'
                ];
                final answers = [
                  '50% needs, 30% wants, 20% savings.',
                  'For unexpected expenses like medical bills.',
                  'Interest on interest earned over time.',
                  'Use budgeting apps or notebooks daily.'
                ];
                return GestureDetector(
                  onTap: () => _showFlipDialog(
                    context,
                    Colors.green,
                    'Rule #${index + 1}',
                    questions[index],
                    answers[index],
                    Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/greencard.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.directions_car,
              label: 'Budget Templates',
              colorx: Colors.yellow,
            ),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: List.generate(4, (index) {
                final questions = [
                  '₹3,000 Budget (Survival Mode)',
                  '₹5,000 Budget (Basic Needs + Fun)',
                  '₹7,000 Budget (Balanced Life)',
                  '₹9,000 Budget (Comfortable & Conscious)'
                ];
                final answers = [
                  '''Food (snacks/outside): ₹600
                    Mobile recharge/internet: ₹300
                    Transport: ₹400
                    Personal care (toiletries, etc.): ₹300
                    College/club expenses: ₹400
                    Entertainment (movies, chai, etc.): ₹400
                    Emergency/savings: ₹600''',
                  '''Food (outside/mess upgrades): ₹1000
                    Transport (bus/Ola/Uber split): ₹600
                    Phone/internet: ₹400
                    Personal care: ₹400
                    College & club activities: ₹700
                    Entertainment & shopping: ₹900
                    Savings/emergency fund: ₹1000''',
                  '''Food (eating out/snacks): ₹1400
                    Transport (shared cabs, etc.): ₹800
                    Phone/internet: ₹500
                    Personal care & hygiene: ₹500
                    College/clubs/materials: ₹800
                    Entertainment, movies, dates: ₹1300
                    Savings/investing: ₹1700''',
                  '''
                    Food (frequent outside meals): ₹2000
                    Transport (auto/Uber/scooter): ₹1000
                    Phone/internet: ₹500
                    Personal care & essentials: ₹600
                    College/clubs/events/books: ₹1000
                    Entertainment/fun/clothes: ₹2000
                    Savings/investments: ₹1900''',
                ];
                return GestureDetector(
                  onTap: () => _showFlipDialog(
                    context,
                    Colors.yellow,
                    'Rule #${index + 1}',
                    questions[index],
                    answers[index],
                    Colors.black87,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/yellowcard.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }),
            ),
            const  SizedBox(height: 24),

            _SectionHeader(
              icon: Icons.directions_car,
              label: 'Smart Spending Habits',
              colorx:Colors.red

            ),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: List.generate(4, (index) {
                final questions = [
                  'How can I avoid impulse purchases?',
                  'Is it okay to use credit cards in college?',
                  'How do I get the best value from online shopping?',
                  'Should I buy or borrow textbooks?'
                ];
                final answers = [
                  'Follow the 24-hour rule: wait a day before buying anything you didn’t plan for.',
                  'Yes, if used wisely. Pay full dues, avoid interest, and don’t spend more than you can repay.',
                  'Compare prices, use student discounts, cashback offers, and coupon extensions like Honey or CashKaro.',
                  'Borrow or buy second-hand to save money. New books are rarely worth it unless you’ll reuse them often.',
                ];
                return GestureDetector(
                  onTap: () => _showFlipDialog(
                    context,
                    Colors.red,
                    'Rule #${index + 1}',
                    questions[index],
                    answers[index],
                    Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/redcard.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }),
            ),


          ],
        ),
      ),
    );
  }
}


