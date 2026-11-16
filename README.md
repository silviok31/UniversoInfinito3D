# Universo Infinito 3D — Protótipo de Sobrevivência

Projeto Godot 4.2+ para Android (renderizador Compatibility). Sem assets de terceiros; cenário, personagem e objetos são gerados por código.

## Jogabilidade
- Mundo 3D com árvores e rochas, câmera em terceira pessoa e personagem explorador.
- Joystick virtual à esquerda; arraste no lado direito para girar a câmera.
- Botão COLETAR perto de árvore ou rocha: +2 madeira ou +2 pedra.
- ABRIGO custa 6 madeiras e 4 pedras, constrói uma estrutura e recupera vida.
- COMER consome 1 madeira (mecânica provisória de fogueira/suprimentos) e restaura fome e sede.
- Vida, fome, sede, cronômetro e salvamento manual local (arquivo user://survival.json).
- No PC: WASD para andar, botão direito do mouse + movimento para girar a câmera.

## Abrir no Godot
1. Instale Godot 4.2 ou superior (versão padrão, não .NET).
2. Clique Importar e selecione `project.godot`.
3. Pressione F6/F5 para executar a cena/projeto.

## Exportar APK no computador
1. Instale OpenJDK 17 e Android SDK (platform-tools, build-tools e plataforma Android).
2. No Godot, instale os templates de exportação correspondentes à sua versão.
3. Editor > Configurações do Editor > Export > Android: configure caminhos para Java SDK e Android SDK.
4. Projeto > Exportar > Android: confira identificador do pacote, arquitetura arm64-v8a e assinatura de depuração.
5. Exporte `build/UniversoInfinito3D.apk` e instale no celular Android.

Também é possível usar a linha de comando após configurar SDK, templates e keystore:
`godot --headless --path . --export-debug Android build/UniversoInfinito3D.apk`

## Estado do projeto
**Protótipo inicial, não um jogo final.** Os gráficos são geometria 3D simples com materiais e iluminação, não modelos realistas detalhados. A posição e os recursos são salvos; as árvores removidas e as estruturas construídas **não são restauradas** ao reabrir o jogo. A IA de inimigos, animações, terreno variado e inventário visual ficam para versões futuras.

O projeto não foi executado ou compilado neste ambiente (Godot e SDK Android não estão instalados). Pode exigir pequenos ajustes de compatibilidade na sua versão da engine.

## APK automatico no GitHub Actions

1. Crie um repositorio no GitHub e envie o **conteudo** desta pasta (incluindo `.github/workflows/android-apk.yml`).
2. Abra **Actions > Compilar APK Android > Run workflow** ou faca push na branch main/master.
3. Aguarde o job `build` concluir com sucesso.
4. Abra a execucao e baixe o artifact `UniversoInfinito3D-Android-APK`.
5. Extraia o ZIP do artifact e instale `UniversoInfinito3D.apk` no Android.

O APK e uma compilacao **debug** para testes, nao uma versao assinada para Play Store. A compilacao exige acesso aos servidores GitHub/Android SDK. Se o job falhar, consulte os logs da etapa com erro. O projeto ainda nao foi testado em dispositivo real.
