//
//  StructuralEvaluator.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 23/10/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

/**
 * Base structural evaluator.
 */
public class StructuralEvaluator: Evaluator {
    let evaluator: Evaluator

    public init(_ evaluator: Evaluator) {
        self.evaluator = evaluator
    }

    public class Root: Evaluator {
        public override func matches(_ root: HTMLElement, _ element: HTMLElement) -> Bool {
            return root === element
        }
    }

    public class Has: StructuralEvaluator {
        public override init(_ evaluator: Evaluator) {
            super.init(evaluator)
        }

        public override func matches(_ root: HTMLElement, _ element: HTMLElement)throws->Bool {
            for e in element.allElements {
                do {
                    if(e != element) {
                        if ((try evaluator.matches(root, e))) {
                            return true
                        }
                    }
                } catch {}
            }

            return false
        }

        public override func toString() -> String {
            return ":has(\(evaluator.toString()))"
        }
    }

    public class Not: StructuralEvaluator {
        public override init(_ evaluator: Evaluator) {
            super.init(evaluator)
        }

        public override func matches(_ root: HTMLElement, _ node: HTMLElement) -> Bool {
            do {
                return try !evaluator.matches(root, node)
            } catch {}
            return false
        }

        public override func toString() -> String {
            return ":not\(evaluator.toString())"
        }
    }

    public class Parent: StructuralEvaluator {
        public override init(_ evaluator: Evaluator) {
            super.init(evaluator)
        }

        public override func matches(_ root: HTMLElement, _ element: HTMLElement) -> Bool {
            if (root == element) {
                return false
            }

            var parent = element.parent
            while (true) {
                do {
                    if let p = parent, try evaluator.matches(root, p) {
                        return true
                    }
                } catch {}

                if (parent == root) {
                    break
                }
                parent = parent?.parent
            }
            return false
        }

        public override func toString() -> String {
            return ":parent\(evaluator.toString())"
        }
    }

    public class ImmediateParent: StructuralEvaluator {
        public override init(_ evaluator: Evaluator) {
            super.init(evaluator)
        }

        public override func matches(_ root: HTMLElement, _ element: HTMLElement) -> Bool {
            if (root == element) {
                return false
            }

            if let parent = element.parent {
                do {
                    return try evaluator.matches(root, parent)
                } catch {}
            }

            return false
        }

        public override func toString() -> String {
            return ":ImmediateParent\(evaluator.toString())"
        }
    }

    public class PreviousSibling: StructuralEvaluator {
        public override init(_ evaluator: Evaluator) {
            super.init(evaluator)
        }

        public override func matches(_ root: HTMLElement, _ element: HTMLElement)throws->Bool {
            if (root == element) {
            return false
            }

            var prev = element.previousSiblingElement

            while (prev != nil) {
                do {
                if (try evaluator.matches(root, prev!)) {
                    return true
                }
                } catch {}

                prev = prev!.previousSiblingElement
            }
            return false
        }

        public override func toString() -> String {
            return ":prev*\(evaluator.toString())"
        }
    }

    class ImmediatePreviousSibling: StructuralEvaluator {
        public override init(_ evaluator: Evaluator) {
            super.init(evaluator)
        }

        public override func matches(_ root: HTMLElement, _ element: HTMLElement)throws->Bool {
            if (root == element) {
                return false
            }

            if let prev = element.previousSiblingElement {
                do {
                    return try evaluator.matches(root, prev)
                } catch {}
            }
            return false
        }

        public override func toString() -> String {
            return ":prev\(evaluator.toString())"
        }
    }
}
