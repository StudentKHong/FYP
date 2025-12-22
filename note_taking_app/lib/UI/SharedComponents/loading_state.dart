import 'package:flutter/material.dart';

class LoadingShimmer extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const LoadingShimmer({super.key, this.itemCount = 5, this.itemHeight = 80});

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late bool _isVisible;

  @override
  void initState() {
    super.initState();

    _isVisible = true;
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return SizedBox.shrink();
    return Column(
      children: List.generate(widget.itemCount, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Card(
                child: Container(
                  height: widget.itemHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade300,
                        Colors.white,
                        Colors.grey.shade300,
                      ],
                      stops: [
                        _animation.value - 0.3,
                        _animation.value,
                        _animation.value + 0.3,
                      ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color color;

  const LoadingIndicator({super.key, this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: color,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionText;
  final VoidCallback? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionText,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(icon),
          SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: Colors.red),
          ),
          if (actionText != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: action,
              label: Text(
                actionText!,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: Icon(Icons.add),
            ),
          ],
        ],
      ),
    );
  }
}
