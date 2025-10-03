import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:livro/features/feed/services/feed_service.dart';
import 'package:intl/intl.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedService _feedService = FeedService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividades'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _feedService.getFeedPointersStream(),
        builder: (context, pointerSnapshot) {
          if (pointerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (pointerSnapshot.hasError) {
            return Center(child: Text('Erro ao carregar feed: ${pointerSnapshot.error}'));
          }
          if (!pointerSnapshot.hasData || pointerSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('O feed de atividades está vazio.\nSiga outros usuários para ver o que eles estão lendo!', textAlign: TextAlign.center),
            );
          }

          final pointerDocs = pointerSnapshot.data!.docs;
          final eventIds = pointerDocs.map((doc) => doc['eventId'] as String).toList();
          
          return FutureBuilder<List<DocumentSnapshot>>(
            future: _feedService.fetchEventsByIds(eventIds),
            builder: (context, eventDetailsSnapshot) {
              if (eventDetailsSnapshot.connectionState == ConnectionState.waiting && !eventDetailsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (eventDetailsSnapshot.hasError) {
                return Center(child: Text('Erro ao carregar eventos: ${eventDetailsSnapshot.error}'));
              }
              if (!eventDetailsSnapshot.hasData || eventDetailsSnapshot.data!.isEmpty) {
                return const Center(child: Text('Nenhum evento para exibir.'));
              }

              final eventDocs = eventDetailsSnapshot.data!;
              
              eventDocs.sort((a, b) {
                Timestamp tsA = pointerDocs.firstWhere((p) => p['eventId'] == a.id)['timestamp'];
                Timestamp tsB = pointerDocs.firstWhere((p) => p['eventId'] == b.id)['timestamp'];
                return tsB.compareTo(tsA);
              });
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: eventDocs.length,
                itemBuilder: (context, index) {
                  final eventDoc = eventDocs[index];
                  final eventData = eventDoc.data() as Map<String, dynamic>;
                  final DateTime eventDateTime = (eventData['timestamp'] as Timestamp).toDate();
                  
                  return _buildEventCard(context, eventDoc, eventDateTime);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Constrói o "frame" do card de evento.
  Widget _buildEventCard(BuildContext context, DocumentSnapshot eventDoc, DateTime eventDateTime) {
    final eventData = eventDoc.data() as Map<String, dynamic>;
    final String authorUsername = eventData['authorUsername'] ?? 'Um usuário';
    final String? authorPhotoUrl = eventData['authorPhotoUrl'];
    final String formattedTime = DateFormat('dd/MM HH:mm').format(eventDateTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: authorPhotoUrl != null ? NetworkImage(authorPhotoUrl) : null,
                      child: authorPhotoUrl == null ? const Icon(Icons.person, size: 20) : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authorUsername,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      formattedTime,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildEventContent(context, eventData),
              ],
            ),
          ),
          _buildActionButtons(context, eventDoc.id),
        ],
      ),
    );
  }

  /// Constrói o conteúdo principal do card, dependendo do tipo de evento.
  Widget _buildEventContent(BuildContext context, Map<String, dynamic> eventData) {
    final String type = eventData['type'] ?? '';
    final String? bookTitle = eventData['bookTitle'];
    final String? bookCoverUrl = eventData['bookCoverUrl'];
    final int rating = eventData['rating'] ?? 0;
    final String? review = eventData['review'];
    final String? followedUsername = eventData['followedUsername'];
    final int currentPage = eventData['currentPage'] ?? 0;
    final int? pageCount = eventData['pageCount'];

    String actionText = '';
    
    switch(type) {
      case 'finished_book':
        actionText = 'terminou de ler "$bookTitle"';
        break;
      case 'rated_book':
        actionText = 'avaliou "$bookTitle"';
        break;
      case 'started_following':
        actionText = 'começou a seguir $followedUsername.';
        break;
      case 'started_reading':
        actionText = 'começou a ler "$bookTitle"';
        break;
      default:
        actionText = 'fez uma nova atividade.';
        break;
    }
    
    // Layout simples para eventos que não são sobre livros
    if (type == 'started_following') {
      return Row(
        children: [
          Icon(Icons.person_add_alt_1_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(actionText, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      );
    }
    
    // Layout rico para todos os eventos sobre livros
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bookCoverUrl != null && bookCoverUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(bookCoverUrl, width: 60, height: 90, fit: BoxFit.cover),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                actionText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              // Mostra estrelas se for evento de avaliação
              if (type == 'rated_book') ...[
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  )),
                ),
              ],
              // Mostra a resenha se for evento de avaliação
              if (type == 'rated_book' && review != null && review.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 3)),
                  ),
                  child: Text(
                    '"$review"',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              // Mostra a barra de progresso se for evento de "começou a ler"
              if (type == 'started_reading' && pageCount != null && pageCount > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (currentPage / pageCount).clamp(0.0, 1.0),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  'Página $currentPage de $pageCount (${((currentPage / pageCount) * 100).toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói a linha de botões de ação (Curtir, Comentar).
  Widget _buildActionButtons(BuildContext context, String eventId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          StreamBuilder<bool>(
            stream: _feedService.hasUserLiked(eventId),
            builder: (context, snapshot) {
              final hasLiked = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  hasLiked ? Icons.favorite : Icons.favorite_border,
                  color: hasLiked ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  _feedService.toggleLike(eventId);
                },
              );
            },
          ),
          StreamBuilder<int>(
            stream: _feedService.getLikeCount(eventId),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox(width: 24);
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Text(count.toString(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade de comentários a ser implementada!')),
              );
            },
          ),
          const Text('0', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}