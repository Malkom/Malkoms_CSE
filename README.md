# Malkoms Current Set Equipped (Malkoms CSE)

Un bouton flottant qui affiche **l'icône du set d'équipement actuellement équipé**
(gestionnaire d'équipement de Blizzard).

## Fonctionnalités

- Affiche l'icône du set équipé ; **le bouton est masqué** tant qu'aucun set n'est équipé.
- **Déplaçable** : glisser le bouton (quand il n'est pas verrouillé).
- **Redimensionnable** : glisser le coin inférieur droit, ou via les sliders Largeur/Hauteur.
  Option **« Conserver le ratio »** pour garder les proportions.
- **Verrouillable** : une fois verrouillé, plus de déplacement ni de redimensionnement
  (clic droit / slash pour rouvrir les options).
- **Thèmes** : Défaut (bordure simple), **ElvUI** (style bouton ElvUI), **Masque**
  (skinné par ton skin Masque actif). Repli automatique sur Défaut si ElvUI/Masque absent.
- **Clic droit** sur le bouton → options. **Clic gauche** : rien (affichage seul).

## Installation

1. Copie le dossier `Malkoms_CSE` dans `World of Warcraft\_retail_\Interface\AddOns\`.
2. `/reload` ou relance le jeu.
3. Équipe un set via le gestionnaire d'équipement : le bouton apparaît.

> Interface ciblée : **12.01 (120100)**. Si marqué « obsolète », coche « Charger les AddOns
> obsolètes » ou ajuste `## Interface:` dans `Malkoms_CSE.toc`.

## Options

Échap → Options → AddOns → **Malkoms CSE**, ou commande **`/mcse`**.

Thème (appliqué **à chaud**, sans /reload), verrouillage, **niveau d'affichage (strata)**,
**opacité**, conserver le ratio, largeur, hauteur, réinitialiser la taille/position.

## Notes

- Dépendances optionnelles : **Masque** et **ElvUI** (uniquement pour le thème correspondant).
  L'addon fonctionne parfaitement seul avec le thème Défaut.
- Auteur : **Malkom**.
