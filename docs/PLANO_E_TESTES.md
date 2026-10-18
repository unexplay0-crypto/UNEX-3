# Plano técnico e matriz de validação

## Arquitetura

- UI: Flutter Material 3, responsiva por largura.
- Estado: estado local em `StatefulWidget` na primeira versão, mantendo serviços separados para facilitar futura migração para um gerenciador de estado quando necessário.
- Conteúdo: `MediaItem` normalizado; `M3uParser` puro, sem rede nem efeitos colaterais.
- Rede/importação: `PlaylistService`, com timeout e validação básica de URL.
- Persistência: `PreferencesService` com `shared_preferences` para URL e favoritos.
- Player: `video_player` / ExoPlayer no Android.

## Matriz de testes

| Cenário | Automatizado nesta versão | Requer dispositivo/servidor |
|---|---:|---:|
| Parser M3U/M3U Plus e atributos | Sim | Não |
| Linhas inválidas e comentários | Sim | Não |
| Favoritos persistentes | Parcialmente preparado; sem teste de integração ainda | Recomendado |
| Carregar playlist HTTP real | Não | Sim |
| HLS ao vivo | Não | Sim, com URL autorizada |
| MP4 com duração conhecida | Não | Sim |
| MPEG-TS direto | Não | Sim; depende do stream/extrator |
| Troca e encerramento repetido do player | Não | Sim |
| Navegação completa por D-pad | Não | Sim, Android TV/emulador |
| APK/AAB e análise Dart | Configurado no workflow | Runner do GitHub |

## Riscos

1. Stream com codec não suportado pelo dispositivo.
2. URLs com token, cabeçalhos HTTP ou cookies especiais.
3. Servidores que bloqueiam requisições fora do app original.
4. Playlist grande ou com codificação fora do padrão.
5. Foco e dimensionamento que variam entre fabricantes de Android TV.
6. Dependências/SDK estáveis podem mudar; o workflow registra falhas reais em vez de ignorar etapas.

## Próxima fase recomendada

Executar o workflow, corrigir quaisquer falhas de análise/compilação e então testar uma pequena matriz de streams autorizados: HLS ao vivo, HLS VOD, MP4 e TS direto. Só depois desses resultados deve-se expandir para EPG, API de catálogo e organização avançada de séries.
